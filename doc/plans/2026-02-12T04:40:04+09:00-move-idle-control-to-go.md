# Move Server Idle Control from Lua to Go

## Context

Currently, idle auto-shutdown for headless Neovim instances is implemented entirely in Lua: each Neovim process tracks `last_activity`, runs a 60-second timer, and calls `vim.cmd("qa!")` when idle too long. The Go daemon only discovers the dead process on the next RPC attempt.

This is fragile — the Lua timer runs inside the same process being managed, cleanup is duplicated between Lua and Go, and the daemon has no visibility into idle state. Moving idle control to Go lets the daemon own the full lifecycle: it already starts/stops Neovim, handles crash recovery, and manages socket cleanup.

## Codex Review Summary

Codex identified concurrency issues in the initial design (mutex-based `lastActivity`):
1. **Reap during in-flight query** — only updating after success means slow queries get reaped
2. **Race in `removeProject`** — closes client without holding `ps.mu`
3. **Deadlock risk** — reaper holding `d.mu` then `ps.mu` inverts lock order with query error path

Resolution: use `atomic.Int64` for `lastActivity` and `atomic.Int32` for `inFlight` counter. Reaper never takes `ps.mu`, avoiding lock-order issues entirely. In-flight counter prevents reaping active projects.

## Changes

### Files to modify

| File | Change |
|------|--------|
| `tools/lsp-gw/server/daemon.go` | Add atomic idle tracking + in-flight counter to `projectState`, add idle reaper goroutine |
| `tools/lsp-gw/server/server.go` | Remove `maxIdleMins` param and `g:lsp_gw_max_idle_mins`/`g:lsp_gw_socket` injection from `StartNeovim` |
| `tools/lsp-gw/server/lua/lsp_gateway/init.lua` | Remove `last_activity`, `touch_activity`, `setup_idle_timer`, `cleanup_runtime_files`, idle fields from `health()` |
| `config/nvim/lua/lsp_gateway/init.lua` | Same Lua removals (keep in sync) |

### 1. `server/daemon.go` — Concurrency-safe idle tracking

Use `atomic.Int64` for both `lastActivity` (UnixNano timestamp) and `inFlight` (active request counter). This avoids lock-order issues entirely — the reaper never needs `ps.mu`.

**`projectState`** (line 20):

```go
type projectState struct {
	mu           sync.Mutex
	nvimSocket   string
	client       *nvim.Nvim
	lastActivity atomic.Int64 // UnixNano timestamp
	inFlight     atomic.Int32 // active request count
}
```

**`ensureNeovim`** (line 130): initialize `lastActivity` when creating a new project.

```go
ps := &projectState{
	nvimSocket: nvimSocket,
	client:     client,
}
ps.lastActivity.Store(time.Now().UnixNano())
```

**`queryNeovim`** (around line 170): touch activity **before** the query starts, and track in-flight count to prevent reaping during active requests.

```go
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
```

**New `startIdleReaper` and `reapIdleProjects`**: lock-free idle check, skip projects with in-flight requests.

```go
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
			continue // skip projects with active requests
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
```

**`Run`** (line 80 area): launch reaper goroutine.

```go
go func() {
	<-ctx.Done()
	d.shutdown()
}()
go d.startIdleReaper(ctx)
```

Add `"sync/atomic"` and `"time"` to imports.

### 2. `server/server.go` — Simplify `StartNeovim`

Remove `maxIdleMins int` parameter and the `--cmd` flags for `g:lsp_gw_max_idle_mins` and `g:lsp_gw_socket`. These Vim globals are no longer read by Lua.

```go
func StartNeovim(nvimSocket, projectRoot, luaDir string) error {
	// ... (keep socket dir creation, stale socket removal)

	luaFile := filepath.Join(luaDir, "lua", "lsp_gateway", "init.lua")
	preloadCmd := fmt.Sprintf(
		"lua package.preload['lsp_gateway'] = loadfile('%s')",
		luaFile,
	)

	cmd := exec.Command("nvim", "--headless", "--listen", nvimSocket,
		"--cmd", preloadCmd)
	// ... rest unchanged
}
```

Update call site in `daemon.go:120`:
```go
if err := StartNeovim(nvimSocket, projectRoot, d.luaDir); err != nil {
```

### 3. Lua changes (both copies)

**Remove** from embedded copy (`tools/lsp-gw/server/lua/lsp_gateway/init.lua`):
- `last_activity` variable (line 12)
- `touch_activity()` function (lines 14-16)
- All `touch_activity()` calls in `M.get_definition`, `M.get_references`, `M.get_hover`, `M.get_document_symbols`, `M.get_diagnostics`, `M.health`
- `cleanup_runtime_files()` function (lines 303-307)
- `setup_idle_timer()` function and its call (lines 309-324)
- `idle_seconds` and `max_idle_minutes` fields from `health()` result (lines 288-289, 298-299)

**Remove** same from interactive copy (`config/nvim/lua/lsp_gateway/init.lua`):
- Same items as above (the interactive copy has a slightly different `cleanup_runtime_files` with sidecar/lock cleanup — remove it all)

### 4. Health response update

Remove `idle_seconds` and `max_idle_minutes` from the Lua `health()` response. No consumers currently depend on these fields. The Go daemon has `lastActivity` per project if we want to expose idle info later.

## Verification

1. `cd tools/lsp-gw && go build ./...` — confirms Go compiles
2. `lsp-gw server start --max-idle 1` — start with 1-min idle for quick test
3. `lsp-gw health <project>` — verify health response no longer has `idle_seconds`/`max_idle_minutes`
4. Wait ~90s without requests — the Neovim process should be reaped (check with `lsp-gw server status`)
5. Make a new request after reap — daemon should auto-start a fresh Neovim instance (existing crash recovery path)
