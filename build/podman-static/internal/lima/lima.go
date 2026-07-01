// Package lima drives a Lima VM used to build podman-static reproducibly,
// independent of the host runtime (macOS or Linux).
//
// The `build` command always builds inside the VM (an intentional design
// choice): the VM is provisioned from Lima's docker template — rootless docker,
// buildx included — and a host directory is mounted writable so the exported
// image filesystem and checked-out repo are read back on the host without any
// extra copy. A persistent, named instance is reused across builds; -recreate
// tears it down first.
//
// It requires Lima 2.0+ (for the `template:` locator form used in `base:`
// inheritance) and shells out only to `limactl`, via LimactlCli.
package lima

import (
	"bufio"
	"bytes"
	"context"
	_ "embed"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"

	"go.yaml.in/yaml/v4"
)

// dnsProvisionScript fixes DNS resolution for the in-VM rootless docker; see
// dns-provision.sh for why it is needed.
//
//go:embed dns-provision.sh
var dnsProvisionScript string

// Config describes the build VM.
type Config struct {
	Name       string // instance name (persistent, reused across builds)
	Template   string // base template ref, default template:docker
	Cpus       int    // vCPUs
	Memory     string // e.g. "8GiB"
	Disk       string // e.g. "60GiB"
	HostWork   string // host directory mounted into the VM (writable)
	MountPoint string // guest path the HostWork is mounted at
}

// Defaults returns a Config with sensible values; Name/HostWork must be set by
// the caller (HostWork is where build artifacts are exchanged).
func Defaults() Config {
	return Config{
		Name:       "podman-static-build",
		Template:   "template:docker",
		Cpus:       4,
		Memory:     "8GiB",
		Disk:       "60GiB",
		MountPoint: "/mnt/psbuild",
	}
}

// LimactlCli is a resolved `limactl` binary used to drive Lima instances. It
// stores only the executable path; construct it with FindCliFromPath. Its
// methods forward that path to the package's unexported implementations.
type LimactlCli struct {
	path string
}

// FindCliFromPath resolves the limactl binary on PATH, returning actionable
// guidance when Lima is not installed.
func FindCliFromPath() (*LimactlCli, error) {
	path, err := exec.LookPath("limactl")
	if err != nil {
		return nil, fmt.Errorf("limactl not found: install Lima (https://lima-vm.io), " +
			"e.g. `brew install lima`, `nix profile install nixpkgs#lima`, or `mise use -g lima`")
	}
	return &LimactlCli{path: path}, nil
}

// Status returns the instance status ("Running", "Stopped", ...) or "" if the
// instance does not exist.
func (l *LimactlCli) Status(ctx context.Context, name string) (string, error) {
	return status(ctx, l.path, name)
}

// Ensure makes the named instance exist and run. When recreate is true an
// existing instance is deleted first. Returns whether a fresh instance was
// created (the caller may want to warn the user about the slow first build).
func (l *LimactlCli) Ensure(
	ctx context.Context,
	c Config,
	recreate bool,
) (created bool, err error) {
	return ensure(ctx, l.path, c, recreate)
}

// RunScript runs a bash script inside the instance, forwarding stdio so build
// output (and any prompt) reaches the user.
func (l *LimactlCli) RunScript(ctx context.Context, name, script string) error {
	return runScript(ctx, l.path, name, script)
}

func status(ctx context.Context, limactl, name string) (string, error) {
	out, err := exec.CommandContext(ctx, limactl, "list", "--json").Output()
	if err != nil {
		return "", fmt.Errorf("limactl list: %w", err)
	}
	sc := bufio.NewScanner(bytes.NewReader(out))
	sc.Buffer(make([]byte, 0, 64*1024), 1024*1024)
	for sc.Scan() {
		line := bytes.TrimSpace(sc.Bytes())
		if len(line) == 0 {
			continue
		}
		var inst struct {
			Name   string `json:"name"`
			Status string `json:"status"`
		}
		if err := json.Unmarshal(line, &inst); err != nil {
			return "", fmt.Errorf("parsing limactl list output: %w", err)
		}
		if inst.Name == name {
			return inst.Status, nil
		}
	}
	return "", sc.Err()
}

func ensure(
	ctx context.Context,
	limactl string,
	c Config,
	recreate bool,
) (created bool, err error) {
	st, err := status(ctx, limactl, c.Name)
	if err != nil {
		return false, err
	}
	if recreate && st != "" {
		if err := run(ctx, limactl, "delete", "--force", c.Name); err != nil {
			return false, err
		}
		st = ""
	}
	switch st {
	case "":
		return true, create(ctx, limactl, c)
	case "Running":
		return false, nil
	default:
		return false, run(ctx, limactl, "start", "--tty=false", c.Name)
	}
}

// create writes an instance config inheriting the docker template and starts it.
func create(ctx context.Context, limactl string, c Config) error {
	if err := os.MkdirAll(c.HostWork, 0o755); err != nil {
		return fmt.Errorf("creating host work dir: %w", err)
	}
	body, err := c.instanceYaml()
	if err != nil {
		return fmt.Errorf("rendering instance config: %w", err)
	}
	f, err := os.CreateTemp("", "lima-podman-static-*.yaml")
	if err != nil {
		return err
	}
	defer func() { _ = os.Remove(f.Name()) }()
	if _, err := f.Write(body); err != nil {
		_ = f.Close()
		return err
	}
	if err := f.Close(); err != nil {
		return err
	}
	return run(ctx, limactl, "start", "--tty=false", "--name="+c.Name, f.Name())
}

func runScript(ctx context.Context, limactl, name, script string) error {
	return run(ctx, limactl, "shell", name, "--", "bash", "-euo", "pipefail", "-c", script)
}

func run(ctx context.Context, limactl string, args ...string) error {
	cmd := exec.CommandContext(ctx, limactl, args...)
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}

// instanceConfig is the subset of Lima's instance YAML this tool emits; the rest
// is inherited from the base template referenced by Base.
type instanceConfig struct {
	Base      string          `yaml:"base"`
	Cpus      int             `yaml:"cpus"`
	Memory    string          `yaml:"memory"`
	Disk      string          `yaml:"disk"`
	Mounts    []instanceMount `yaml:"mounts"`
	Provision []provisionStep `yaml:"provision"`
}

type instanceMount struct {
	Location   string `yaml:"location"`
	MountPoint string `yaml:"mountPoint"`
	Writable   bool   `yaml:"writable"`
}

type provisionStep struct {
	Mode   string `yaml:"mode"`
	Script string `yaml:"script"`
}

// instanceYaml marshals the Lima instance config. It always includes the DNS
// provision (dnsProvisionScript) because rootless docker's gvisor-tap-vsock
// network namespace cannot reach systemd-resolved's 127.0.0.53 stub.
func (c Config) instanceYaml() ([]byte, error) {
	return yaml.Marshal(instanceConfig{
		Base:   c.Template,
		Cpus:   c.Cpus,
		Memory: c.Memory,
		Disk:   c.Disk,
		Mounts: []instanceMount{{
			Location:   c.HostWork,
			MountPoint: c.MountPoint,
			Writable:   true,
		}},
		Provision: []provisionStep{{
			Mode:   "system",
			Script: dnsProvisionScript,
		}},
	})
}
