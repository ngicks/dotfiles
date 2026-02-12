package server

import (
	"context"
	"fmt"
	"log"
	"net"
	"os"
	"path/filepath"
	"sync"
	"sync/atomic"
	"time"

	"github.com/neovim/go-client/nvim"
	"github.com/watage/lsp-gw/gateway"
	pb "github.com/watage/lsp-gw/proto"
	"golang.org/x/sync/singleflight"
	"google.golang.org/grpc"
	"google.golang.org/protobuf/types/known/structpb"
)

type projectState struct {
	mu           sync.Mutex
	nvimSocket   string
	client       *nvim.Nvim
	lastActivity atomic.Int64  // UnixNano timestamp
	inFlight     atomic.Int32  // active request count
}

// Daemon is the gRPC server that manages neovim processes.
type Daemon struct {
	pb.UnimplementedLspGatewayServer
	socket      string
	luaDir      string
	maxIdleMins int
	mu          sync.Mutex
	projects    map[string]*projectState
	sf          singleflight.Group
	grpcServer  *grpc.Server
	listener    net.Listener
	cancel      context.CancelFunc
}

// NewDaemon creates a new daemon instance.
func NewDaemon(socket string, maxIdleMins int) *Daemon {
	return &Daemon{
		socket:      socket,
		maxIdleMins: maxIdleMins,
		projects:    make(map[string]*projectState),
	}
}

// Run prepares the Lua runtime, starts the gRPC server, and blocks until ctx is cancelled.
func (d *Daemon) Run(ctx context.Context) error {
	ctx, d.cancel = context.WithCancel(ctx)

	luaDir, err := PrepareLuaRuntime()
	if err != nil {
		return fmt.Errorf("prepare lua runtime: %w", err)
	}
	d.luaDir = luaDir

	if err := os.MkdirAll(SocketDir(), 0o700); err != nil {
		CleanupLuaRuntime(luaDir)
		return fmt.Errorf("mkdir socket dir: %w", err)
	}

	// Remove stale daemon socket
	os.Remove(d.socket)

	lis, err := net.Listen("unix", d.socket)
	if err != nil {
		CleanupLuaRuntime(luaDir)
		return fmt.Errorf("listen %s: %w", d.socket, err)
	}
	d.listener = lis

	d.grpcServer = grpc.NewServer()
	pb.RegisterLspGatewayServer(d.grpcServer, d)

	log.Printf("daemon listening on %s", d.socket)

	// Shut down gracefully when context is cancelled
	go func() {
		<-ctx.Done()
		d.shutdown()
	}()
	go d.startIdleReaper(ctx)

	if err := d.grpcServer.Serve(lis); err != nil {
		return fmt.Errorf("grpc serve: %w", err)
	}
	return nil
}

func (d *Daemon) shutdown() {
	d.mu.Lock()
	projects := make(map[string]*projectState, len(d.projects))
	for k, v := range d.projects {
		projects[k] = v
	}
	d.projects = make(map[string]*projectState)
	d.mu.Unlock()

	for _, ps := range projects {
		ps.client.Close()
		_ = StopNeovim(ps.nvimSocket)
	}

	CleanupLuaRuntime(d.luaDir)
	d.grpcServer.GracefulStop()
	os.Remove(d.socket)
}

func (d *Daemon) ensureNeovim(projectRoot string) (*projectState, error) {
	result, err, _ := d.sf.Do(projectRoot, func() (any, error) {
		d.mu.Lock()
		if ps, ok := d.projects[projectRoot]; ok {
			d.mu.Unlock()
			return ps, nil
		}
		d.mu.Unlock()

		nvimSocket := NvimSocketPath(projectRoot)
		if err := StartNeovim(nvimSocket, projectRoot, d.luaDir); err != nil {
			return nil, fmt.Errorf("start neovim for %s: %w", projectRoot, err)
		}

		client, err := gateway.Connect(nvimSocket)
		if err != nil {
			_ = StopNeovim(nvimSocket)
			return nil, fmt.Errorf("connect neovim for %s: %w", projectRoot, err)
		}

		ps := &projectState{
			nvimSocket: nvimSocket,
			client:     client,
		}
		ps.lastActivity.Store(time.Now().UnixNano())

		d.mu.Lock()
		d.projects[projectRoot] = ps
		d.mu.Unlock()

		return ps, nil
	})
	if err != nil {
		return nil, err
	}
	return result.(*projectState), nil
}

func (d *Daemon) removeProject(projectRoot string) {
	d.mu.Lock()
	ps, ok := d.projects[projectRoot]
	if ok {
		delete(d.projects, projectRoot)
	}
	d.mu.Unlock()

	if ok {
		ps.client.Close()
		_ = StopNeovim(ps.nvimSocket)
	}
}

// queryNeovim executes a Lua query against the neovim for the given project.
// On error, it removes the project and retries once (handles neovim crashes).
func (d *Daemon) queryNeovim(projectRoot, luaCode string, args ...any) (map[string]any, error) {
	for attempt := range 2 {
		ps, err := d.ensureNeovim(projectRoot)
		if err != nil {
			return nil, err
		}

		ps.inFlight.Add(1)
		ps.lastActivity.Store(time.Now().UnixNano())

		ps.mu.Lock()
		result, err := gateway.QueryGateway(ps.client, luaCode, args...)
		ps.mu.Unlock()

		ps.lastActivity.Store(time.Now().UnixNano())
		ps.inFlight.Add(-1)

		if err != nil {
			if attempt == 0 {
				d.removeProject(projectRoot)
				continue
			}
			return nil, err
		}

		m, ok := result.(map[string]any)
		if !ok {
			return nil, fmt.Errorf("unexpected result type: %T", result)
		}
		return m, nil
	}
	return nil, fmt.Errorf("unreachable")
}

// unwrapLuaResult converts a Lua {ok, error, result} map into a QueryResponse.
func unwrapLuaResult(m map[string]any) (*pb.QueryResponse, error) {
	resp := &pb.QueryResponse{}

	if ok, _ := m["ok"].(bool); ok {
		resp.Ok = true
	}
	if errMsg, _ := m["error"].(string); errMsg != "" {
		resp.Error = errMsg
	}

	if r, exists := m["result"]; exists && r != nil {
		val, err := toProtoValue(r)
		if err != nil {
			return nil, fmt.Errorf("convert result to proto value: %w", err)
		}
		resp.Result = val
	}

	return resp, nil
}

// toProtoValue converts an arbitrary Go value to a protobuf Value.
func toProtoValue(v any) (*structpb.Value, error) {
	switch val := v.(type) {
	case nil:
		return structpb.NewNullValue(), nil
	case bool:
		return structpb.NewBoolValue(val), nil
	case string:
		return structpb.NewStringValue(val), nil
	case int:
		return structpb.NewNumberValue(float64(val)), nil
	case int64:
		return structpb.NewNumberValue(float64(val)), nil
	case uint64:
		return structpb.NewNumberValue(float64(val)), nil
	case float64:
		return structpb.NewNumberValue(val), nil
	case []any:
		list := make([]*structpb.Value, 0, len(val))
		for _, item := range val {
			pv, err := toProtoValue(item)
			if err != nil {
				return nil, err
			}
			list = append(list, pv)
		}
		return structpb.NewListValue(&structpb.ListValue{Values: list}), nil
	case map[string]any:
		fields := make(map[string]*structpb.Value, len(val))
		for k, item := range val {
			pv, err := toProtoValue(item)
			if err != nil {
				return nil, err
			}
			fields[k] = pv
		}
		return structpb.NewStructValue(&structpb.Struct{Fields: fields}), nil
	default:
		return structpb.NewStringValue(fmt.Sprintf("%v", val)), nil
	}
}

// resolveFilepath makes a filepath absolute relative to the project root.
func resolveFilepath(project, fp string) string {
	if filepath.IsAbs(fp) {
		return fp
	}
	return filepath.Join(project, fp)
}

// gRPC method implementations

func (d *Daemon) GetDefinition(_ context.Context, req *pb.LocationRequest) (*pb.QueryResponse, error) {
	fp := resolveFilepath(req.Project, req.Filepath)
	m, err := d.queryNeovim(req.Project, gateway.LuaGetDefinition, fp, int(req.Line), int(req.Col))
	if err != nil {
		return &pb.QueryResponse{Ok: false, Error: err.Error()}, nil
	}
	return unwrapLuaResult(m)
}

func (d *Daemon) GetReferences(_ context.Context, req *pb.LocationRequest) (*pb.QueryResponse, error) {
	fp := resolveFilepath(req.Project, req.Filepath)
	m, err := d.queryNeovim(req.Project, gateway.LuaGetReferences, fp, int(req.Line), int(req.Col))
	if err != nil {
		return &pb.QueryResponse{Ok: false, Error: err.Error()}, nil
	}
	return unwrapLuaResult(m)
}

func (d *Daemon) GetHover(_ context.Context, req *pb.LocationRequest) (*pb.QueryResponse, error) {
	fp := resolveFilepath(req.Project, req.Filepath)
	m, err := d.queryNeovim(req.Project, gateway.LuaGetHover, fp, int(req.Line), int(req.Col))
	if err != nil {
		return &pb.QueryResponse{Ok: false, Error: err.Error()}, nil
	}
	return unwrapLuaResult(m)
}

func (d *Daemon) GetDocumentSymbols(_ context.Context, req *pb.FileRequest) (*pb.QueryResponse, error) {
	fp := resolveFilepath(req.Project, req.Filepath)
	m, err := d.queryNeovim(req.Project, gateway.LuaGetDocumentSymbols, fp)
	if err != nil {
		return &pb.QueryResponse{Ok: false, Error: err.Error()}, nil
	}
	return unwrapLuaResult(m)
}

func (d *Daemon) GetDiagnostics(_ context.Context, req *pb.FileRequest) (*pb.QueryResponse, error) {
	fp := resolveFilepath(req.Project, req.Filepath)
	m, err := d.queryNeovim(req.Project, gateway.LuaGetDiagnostics, fp)
	if err != nil {
		return &pb.QueryResponse{Ok: false, Error: err.Error()}, nil
	}
	return unwrapLuaResult(m)
}

func (d *Daemon) Health(_ context.Context, req *pb.ProjectRequest) (*pb.QueryResponse, error) {
	m, err := d.queryNeovim(req.Project, gateway.LuaHealth)
	if err != nil {
		return &pb.QueryResponse{Ok: false, Error: err.Error()}, nil
	}
	return unwrapLuaResult(m)
}

func (d *Daemon) DaemonStatus(_ context.Context, _ *pb.DaemonStatusRequest) (*pb.QueryResponse, error) {
	d.mu.Lock()
	projects := make(map[string]*structpb.Value, len(d.projects))
	for root, ps := range d.projects {
		projects[root] = structpb.NewStructValue(&structpb.Struct{
			Fields: map[string]*structpb.Value{
				"socket":  structpb.NewStringValue(ps.nvimSocket),
				"running": structpb.NewBoolValue(IsServerRunning(ps.nvimSocket)),
			},
		})
	}
	d.mu.Unlock()

	result := structpb.NewStructValue(&structpb.Struct{
		Fields: map[string]*structpb.Value{
			"daemon_socket": structpb.NewStringValue(d.socket),
			"projects":      structpb.NewStructValue(&structpb.Struct{Fields: projects}),
		},
	})

	return &pb.QueryResponse{Ok: true, Result: result}, nil
}

func (d *Daemon) startIdleReaper(ctx context.Context) {
	if d.maxIdleMins <= 0 {
		return
	}
	maxIdle := time.Duration(d.maxIdleMins) * time.Minute
	ticker := time.NewTicker(60 * time.Second)
	defer ticker.Stop()
	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			d.reapIdleProjects(maxIdle)
		}
	}
}

func (d *Daemon) reapIdleProjects(maxIdle time.Duration) {
	now := time.Now()
	d.mu.Lock()
	var toRemove []string
	for root, ps := range d.projects {
		if ps.inFlight.Load() > 0 {
			continue
		}
		lastNano := ps.lastActivity.Load()
		idle := now.Sub(time.Unix(0, lastNano))
		if idle >= maxIdle {
			toRemove = append(toRemove, root)
		}
	}
	d.mu.Unlock()

	for _, root := range toRemove {
		log.Printf("reaping idle neovim for %s", root)
		d.removeProject(root)
	}
}

func (d *Daemon) Shutdown(_ context.Context, _ *pb.ShutdownRequest) (*pb.QueryResponse, error) {
	go func() {
		if d.cancel != nil {
			d.cancel()
		}
	}()
	return &pb.QueryResponse{Ok: true, Result: structpb.NewStringValue("shutting down")}, nil
}
