// Package build produces the distribution artifact: it provisions a Lima VM,
// builds podman-static inside it with docker, then assembles the tree and
// compresses it to a tar.zst on the host.
//
// The heavy build runs in the VM (one `docker build --output=type=local`); the
// host reads the exported filesystem back over the shared mount and does the
// layout + compression in Go (see internal/asset and writeArtifact).
package build

import (
	"context"
	"fmt"
	"io/fs"
	"os"
	"path/filepath"

	"github.com/ngicks/podman-static-dist/internal/asset"
	"github.com/ngicks/podman-static-dist/internal/lima"
	"github.com/ngicks/podman-static-dist/internal/repo"
)

const repoUrl = "https://github.com/mgoltzsche/podman-static"

// Option configures Run.
type Option struct {
	Tag        string      // required: podman-static tag to build (e.g. v5.8.4)
	ConfFS     fs.FS       // required: conf/ overlaid into the tree (embedded resources)
	EnvFS      fs.FS       // optional: environment.d/ files delivered in the tree
	OutputPath string      // required: destination .tar.zst
	Recreate   bool        // recreate the VM before building
	Vm         lima.Config // VM config; HostWork defaults next to OutputPath
	// Confirm, when set, is asked before provisioning a fresh (slow) VM. A
	// false return aborts the build.
	Confirm func(prompt string) (bool, error)
}

// Validate reports whether the required fields are set. Run calls it before use.
func (o Option) Validate() error {
	if o.Tag == "" {
		return fmt.Errorf("tag is required")
	}
	if o.ConfFS == nil {
		return fmt.Errorf("conf fs is required")
	}
	if o.OutputPath == "" {
		return fmt.Errorf("output path is required")
	}
	return nil
}

// Run performs the full build.
func Run(ctx context.Context, o Option) error {
	if err := o.Validate(); err != nil {
		return err
	}

	cli, err := lima.FindCliFromPath()
	if err != nil {
		return err
	}

	vm := o.Vm
	if vm.Name == "" {
		vm = lima.Defaults()
	}
	if vm.HostWork == "" {
		vm.HostWork = defaultHostWork(o.OutputPath)
	}

	// Confirm before creating a fresh VM (first build / -recreate): it is slow.
	if o.Confirm != nil {
		status, err := cli.Status(ctx, vm.Name)
		if err != nil {
			return err
		}
		if status == "" || o.Recreate {
			ok, err := o.Confirm(fmt.Sprintf("Lima VM %q must be %s (this is slow). Proceed?",
				vm.Name, ternary(status == "", "created", "recreated")))
			if err != nil {
				return err
			}
			if !ok {
				return fmt.Errorf("aborted by user")
			}
		}
	}

	if _, err := cli.Ensure(ctx, vm, o.Recreate); err != nil {
		return fmt.Errorf("provisioning VM: %w", err)
	}

	// Check out podman-static on the host (git lives here, not in the VM). The
	// work tree sits on the shared mount, so the in-VM docker build reads it.
	repoDir := filepath.Join(vm.HostWork, "podman-static")
	if err := repo.Sync(ctx, repoDir, repoUrl, o.Tag); err != nil {
		return fmt.Errorf("checking out podman-static: %w", err)
	}

	// The Lima docker template runs rootless docker, so no sudo is needed.
	if err := cli.RunScript(ctx, vm.Name, buildScript(vm.MountPoint)); err != nil {
		return fmt.Errorf("building in VM: %w", err)
	}

	// The VM wrote the exported filesystem into MountPoint/rootfs, visible on
	// the host at HostWork/rootfs.
	rootfs := filepath.Join(vm.HostWork, "rootfs")
	assetDir := filepath.Join(vm.HostWork, "podman-linux-amd64")
	if err := asset.Assemble(ctx, asset.Params{
		RootfsDir: rootfs,
		RepoDir:   repoDir,
		ConfFS:    o.ConfFS,
		EnvFS:     o.EnvFS,
		DestDir:   assetDir,
	}); err != nil {
		return fmt.Errorf("assembling asset tree: %w", err)
	}

	if err := os.MkdirAll(filepath.Dir(o.OutputPath), 0o755); err != nil {
		return err
	}
	if err := writeArtifact(assetDir, o.OutputPath); err != nil {
		return fmt.Errorf("writing artifact: %w", err)
	}
	return nil
}

// buildScript is the bash run inside the VM: export the tar-archive stage
// filesystem of the already-checked-out repo to the shared mount. The repo is
// checked out on the host (see repo.Sync), so this needs docker but not git;
// the Lima docker template is rootless, so docker runs without sudo.
func buildScript(mountPoint string) string {
	return fmt.Sprintf(`
WORK=%q
REPO="$WORK/podman-static"
rm -rf "$WORK/rootfs"
docker build --platform=linux/amd64 --output=type=local,dest="$WORK/rootfs" \
  --target tar-archive "$REPO"
`, mountPoint)
}

// defaultHostWork places the VM's shared work dir next to the output artifact.
func defaultHostWork(outputPath string) string {
	abs, err := filepath.Abs(outputPath)
	if err != nil {
		abs = outputPath
	}
	return filepath.Join(filepath.Dir(abs), ".podman-static-build")
}

func ternary(cond bool, a, b string) string {
	if cond {
		return a
	}
	return b
}
