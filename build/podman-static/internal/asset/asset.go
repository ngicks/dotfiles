// Package asset assembles the podman-linux-<arch> distribution tree on the host,
// in Go, replicating upstream podman-static's `.podman-from-container` and `tar`
// Makefile targets.
//
// Inputs are produced inside the Lima VM (the exported image rootfs and the
// checked-out repo) and read back over the shared mount; assembling here keeps
// the layout logic host-side, CGO-free, and unit-testable — the VM only runs
// `docker build`.
//
// The resulting tree is:
//
//	etc/containers/                              <- rootfs /etc/containers, then our conf/ overlaid
//
// (un-interpolated)
//
//	usr/local/{bin,lib,libexec}/                 <- rootfs /usr/local/{bin,lib,libexec}
//	usr/local/share/{bash-completion,zsh,fish}/  <- rootfs shell completions
//	usr/local/lib/systemd/{system,user}/         <- repo conf/systemd/*.service|.socket
//	usr/local/lib/systemd/{system,user}-generators/podman-*-generator ->
//
// ../../../libexec/podman/quadlet
//
//	usr/local/lib/environment.d/                 <- our environment.d/ files (optional)
//	README.md                                    <- repo README.md
package asset

import (
	"context"
	"fmt"
	"io"
	"io/fs"
	"os"
	"path/filepath"
)

// Params are the inputs to Assemble.
type Params struct {
	RootfsDir string // exported image filesystem (contains etc/, usr/local/...)
	RepoDir   string // checked-out podman-static repo (README.md, conf/systemd/)
	ConfFS    fs.FS  // our conf/ overlaid into etc/containers, un-interpolated
	EnvFS     fs.FS  // our environment.d/ files; optional, skipped when nil
	DestDir   string // asset tree root to (re)create, e.g. <work>/podman-linux-amd64
}

// systemdUnits are installed into both the system and user unit directories,
// matching upstream's `tar` target.
var systemdUnits = []string{"podman-restart.service", "podman.service", "podman.socket"}

// localSubdirs are copied wholesale from rootfs /usr/local.
var localSubdirs = []string{"bin", "lib", "libexec"}

// shareSubdirs are shell completions; optional (skipped if absent upstream).
var shareSubdirs = []string{"bash-completion", "zsh", "fish"}

// Assemble (re)creates p.DestDir with the full distribution tree.
func Assemble(ctx context.Context, p Params) error {
	if err := os.RemoveAll(p.DestDir); err != nil {
		return fmt.Errorf("clearing dest: %w", err)
	}

	// /etc/containers from the image, then our conf overlaid un-interpolated.
	if err := copyTree(
		ctx,
		filepath.Join(p.RootfsDir, "etc/containers"),
		filepath.Join(p.DestDir, "etc/containers"),
	); err != nil {
		return fmt.Errorf("copying etc/containers: %w", err)
	}
	if err := copyRegularFiles(
		ctx,
		p.ConfFS,
		filepath.Join(p.DestDir, "etc/containers"),
	); err != nil {
		return fmt.Errorf("overlaying conf: %w", err)
	}

	// Our environment.d/ fragment, delivered un-interpolated under usr/local/lib
	// (reachable via the ~/.local/containers symlink) and linked into
	// ~/.config/environment.d at install time, like the systemd user units.
	if p.EnvFS != nil {
		dst := filepath.Join(p.DestDir, "usr/local/lib/environment.d")
		if err := copyRegularFiles(ctx, p.EnvFS, dst); err != nil {
			return fmt.Errorf("copying environment.d: %w", err)
		}
	}

	// /usr/local/{bin,lib,libexec}
	for _, sub := range localSubdirs {
		if err := copyTree(
			ctx,
			filepath.Join(p.RootfsDir, "usr/local", sub),
			filepath.Join(p.DestDir, "usr/local", sub),
		); err != nil {
			return fmt.Errorf("copying usr/local/%s: %w", sub, err)
		}
	}

	// /usr/local/share/{bash-completion,zsh,fish} (optional)
	for _, sub := range shareSubdirs {
		src := filepath.Join(p.RootfsDir, "usr/local/share", sub)
		if _, err := os.Stat(src); err != nil {
			if os.IsNotExist(err) {
				continue
			}
			return err
		}
		if err := copyTree(ctx, src, filepath.Join(p.DestDir, "usr/local/share", sub)); err != nil {
			return fmt.Errorf("copying usr/local/share/%s: %w", sub, err)
		}
	}

	// systemd unit files into both system and user directories.
	for _, scope := range []string{"system", "user"} {
		dir := filepath.Join(p.DestDir, "usr/local/lib/systemd", scope)
		for _, unit := range systemdUnits {
			src := filepath.Join(p.RepoDir, "conf/systemd", unit)
			if err := copyFile(src, filepath.Join(dir, unit), 0o644); err != nil {
				return fmt.Errorf("installing systemd unit %s: %w", unit, err)
			}
		}
	}

	// quadlet generator symlinks (relative, into libexec/podman/quadlet).
	const quadletRel = "../../../libexec/podman/quadlet"
	generators := map[string]string{
		"usr/local/lib/systemd/system-generators/podman-system-generator": quadletRel,
		"usr/local/lib/systemd/user-generators/podman-user-generator":     quadletRel,
	}
	for rel, target := range generators {
		if err := symlink(target, filepath.Join(p.DestDir, rel)); err != nil {
			return fmt.Errorf("linking generator %s: %w", rel, err)
		}
	}

	// README.md alongside the tree, as upstream does.
	if err := copyFile(
		filepath.Join(p.RepoDir, "README.md"),
		filepath.Join(p.DestDir, "README.md"),
		0o644,
	); err != nil {
		return fmt.Errorf("copying README.md: %w", err)
	}
	return nil
}

// copyRegularFiles copies every regular file in srcFS into dst, verbatim —
// interpolation is deferred to install time (requirement 5/6). Used for both the
// etc/containers conf overlay and the environment.d fragment. Files are written
// 0644 (embed.FS reports its files read-only, so the source mode is not kept).
func copyRegularFiles(ctx context.Context, srcFS fs.FS, dst string) error {
	entries, err := fs.ReadDir(srcFS, ".")
	if err != nil {
		return err
	}
	for _, e := range entries {
		if cerr := ctx.Err(); cerr != nil {
			return cerr
		}
		if !e.Type().IsRegular() {
			return fmt.Errorf("resource dir contains non-regular file: %s", e.Name())
		}
		data, err := fs.ReadFile(srcFS, e.Name())
		if err != nil {
			return err
		}
		target := filepath.Join(dst, e.Name())
		if err := os.MkdirAll(filepath.Dir(target), 0o755); err != nil {
			return err
		}
		if err := os.WriteFile(target, data, 0o644); err != nil {
			return err
		}
	}
	return nil
}

// copyTree recursively copies src to dst, preserving file modes and symlinks.
func copyTree(ctx context.Context, src, dst string) error {
	return filepath.WalkDir(src, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if cerr := ctx.Err(); cerr != nil {
			return cerr
		}
		rel, err := filepath.Rel(src, path)
		if err != nil {
			return err
		}
		target := filepath.Join(dst, rel)
		info, err := d.Info()
		if err != nil {
			return err
		}
		switch {
		case info.Mode()&fs.ModeSymlink != 0:
			link, err := os.Readlink(path)
			if err != nil {
				return err
			}
			return symlink(link, target)
		case d.IsDir():
			return os.MkdirAll(target, 0o755)
		case info.Mode().IsRegular():
			return copyFile(path, target, info.Mode().Perm())
		default:
			return fmt.Errorf("unsupported file type: %s", path)
		}
	})
}

func copyFile(src, dst string, perm fs.FileMode) (err error) {
	if err := os.MkdirAll(filepath.Dir(dst), 0o755); err != nil {
		return err
	}
	in, err := os.Open(src)
	if err != nil {
		return err
	}
	defer closeOnce(&err, in)
	out, err := os.OpenFile(dst, os.O_CREATE|os.O_WRONLY|os.O_TRUNC, perm)
	if err != nil {
		return err
	}
	defer closeOnce(&err, out)
	_, err = io.Copy(out, in)
	return err
}

func symlink(target, dst string) error {
	if err := os.MkdirAll(filepath.Dir(dst), 0o755); err != nil {
		return err
	}
	if err := os.Remove(dst); err != nil && !os.IsNotExist(err) {
		return err
	}
	return os.Symlink(target, dst)
}

func closeOnce(err *error, c io.Closer) {
	if cerr := c.Close(); cerr != nil && *err == nil {
		*err = cerr
	}
}
