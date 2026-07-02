package buildpodman

import (
	"context"
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
)

// OverlayParams configures Overlay.
type OverlayParams struct {
	AssetDir string // the distribution tree `make singlearch-tar` produced
	ConfFS   fs.FS  // our conf/ files, overlaid into etc/containers (overwriting upstream)
	EnvFS    fs.FS  // our environment.d/ files; optional, skipped when nil
}

// Overlay writes our configuration on top of the tree that upstream's
// `make singlearch-tar` already assembled (the whole podman-linux-<arch> layout
// — binaries, systemd units, generator symlinks, upstream etc/containers).
//
// Our conf/ files overwrite the upstream etc/containers, and our environment.d/
// fragment is delivered under usr/local/lib (reachable via the ~/.local/containers
// symlink and linked into ~/.config/environment.d at install time). Both are
// written verbatim; interpolation is deferred to install time.
func Overlay(ctx context.Context, p OverlayParams) error {
	if err := copyRegularFiles(
		ctx,
		p.ConfFS,
		filepath.Join(p.AssetDir, "etc/containers"),
	); err != nil {
		return fmt.Errorf("overlaying conf: %w", err)
	}
	if p.EnvFS != nil {
		dst := filepath.Join(p.AssetDir, "usr/local/lib/environment.d")
		if err := copyRegularFiles(ctx, p.EnvFS, dst); err != nil {
			return fmt.Errorf("copying environment.d: %w", err)
		}
	}
	return nil
}

// copyRegularFiles copies every regular file in srcFS into dst, verbatim. Files
// are written 0644 (embed.FS reports its files read-only, so the source mode is
// not kept).
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
