package install

import (
	"context"
	"fmt"
	"io/fs"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/ngicks/podman-static-dist/internal/buildpodman"
)

// LinkOption configures Link.
type LinkOption struct {
	// Base is the dist base dir holding per-tag installs and the `current`
	// link. When empty it defaults to Env.podmanBase() (TARGET_ARTIFACT_DIR, else
	// XDG_DATA_HOME/podman).
	Base string
	// Tag, when set, (re)points `current` at it — but only when Base is writable.
	// A read-only Base with an existing `current` is tolerated (the tree is a
	// read-only mount inside the devenv container).
	Tag string
	// AdditionalImageStores are injected into storage.conf's
	// additionalimagestores list.
	AdditionalImageStores []string
	// SkipSystemd disables the systemd unit links, quadlet generator, and
	// daemon-reload. They are auto-skipped too when systemctl is not on PATH.
	SkipSystemd bool
	// Env carries the caller's HOME / XDG paths; ArtifactDir feeds the Base
	// default.
	Env Env
	// ConfFS is the embedded resource conf/ (containers.conf, storage.conf,
	// path.env, path.sh) re-materialized against the current environment.
	ConfFS fs.FS
}

// Validate reports whether the required fields are set. Link calls it first.
func (o LinkOption) Validate() error {
	if o.Env.Home == "" {
		return fmt.Errorf("env HOME is required")
	}
	if o.ConfFS == nil {
		return fmt.Errorf("conf fs is required")
	}
	return nil
}

// Link wires an already-extracted dist tree into the caller's home without
// re-extracting it. It is designed to run inside the devenv container, where the
// dist dir is a READ-ONLY mount and $HOME differs from the host that produced the
// tree.
//
// Unlike Symlink, it does not symlink ~/.config/containers wholesale into the
// tree: the host interpolated that tree against the host's $HOME, so a symlink
// would leak host paths. Instead it materializes ~/.config/containers as a real
// directory, rewriting the embedded conf against the CURRENT environment, and
// per-file symlinks the remaining (host-neutral) files from the tree.
//
// It is idempotent: materialized files are overwritten and links recreated on
// every run; unrelated entries in the target dirs are left untouched.
func Link(ctx context.Context, o LinkOption) error {
	if err := o.Validate(); err != nil {
		return err
	}

	base := o.Base
	if base == "" {
		base = o.Env.podmanBase()
	}
	current := filepath.Join(base, "current")

	// (0) current symlink: point it at Tag when given and Base is writable;
	// tolerate a read-only Base as long as current already resolves.
	if o.Tag != "" {
		if err := replaceSymlink(o.Tag, current); err != nil {
			fi, statErr := os.Lstat(current)
			if statErr != nil || fi.Mode()&os.ModeSymlink == 0 {
				return fmt.Errorf("linking current -> %s: %w", o.Tag, err)
			}
			fmt.Fprintf(os.Stderr,
				"notice: base %q is not writable; keeping existing current symlink\n", base)
		}
	}
	if _, err := os.Lstat(current); err != nil {
		return fmt.Errorf(
			"no current symlink at %s (pass --tag on a writable base to create it): %w",
			current, err)
	}

	localContainers := filepath.Join(o.Env.Home, ".local/containers")

	// (a) ~/.local/containers -> current/usr/local (as Symlink's wire does).
	if err := replaceSymlink(filepath.Join(current, "usr/local"), localContainers); err != nil {
		return fmt.Errorf("linking local containers: %w", err)
	}

	// (b) ~/.config/containers as a real directory (see the doc comment).
	if err := materializeConfigDir(o.Env, current, o.ConfFS, o.AdditionalImageStores); err != nil {
		return fmt.Errorf("materializing config dir: %w", err)
	}

	// (c) environment.d per-file links (always, independent of --skip-systemd).
	if err := linkFiles(
		filepath.Join(current, "usr/local/lib/environment.d"),
		filepath.Join(o.Env.ConfigHome, "environment.d"),
		filepath.Join(localContainers, "lib/environment.d"),
	); err != nil {
		return fmt.Errorf("linking environment.d: %w", err)
	}

	// (d) systemd pieces, unless skipped explicitly or systemctl is absent.
	if o.SkipSystemd {
		return nil
	}
	if _, err := exec.LookPath("systemctl"); err != nil {
		fmt.Fprintln(os.Stderr, "notice: systemctl not found on PATH; skipping "+
			"systemd unit links, quadlet generator, and daemon-reload")
		return nil
	}
	if err := linkFiles(
		filepath.Join(current, "usr/local/lib/systemd/user"),
		filepath.Join(o.Env.ConfigHome, "systemd/user"),
		filepath.Join(localContainers, "lib/systemd/user"),
	); err != nil {
		return fmt.Errorf("linking user units: %w", err)
	}
	if err := installQuadletGenerator(ctx, o.Env); err != nil {
		return err
	}
	daemonReload(ctx)
	return nil
}

// materializeConfigDir builds ~/.config/containers as a real directory: each
// embedded conf file is written interpolated against the current environment
// (only ${HOME} / ${XDG_DATA_HOME}); storage.conf additionally gets the
// additional image stores injected. Every other file in current/etc/containers
// is per-file symlinked (those are host-neutral). A prior wholesale symlink left
// by Symlink is replaced with the real directory.
func materializeConfigDir(env Env, current string, confFS fs.FS, stores []string) error {
	configDir := filepath.Join(env.ConfigHome, "containers")
	if fi, err := os.Lstat(configDir); err == nil && fi.Mode()&os.ModeSymlink != 0 {
		if err := os.Remove(configDir); err != nil {
			return fmt.Errorf("removing config dir symlink: %w", err)
		}
	}
	if err := os.MkdirAll(configDir, 0o755); err != nil {
		return err
	}

	ienv := buildpodman.InterpEnv{Home: env.Home, XdgDataHome: env.DataHome}

	embeddedNames := map[string]bool{}
	entries, err := fs.ReadDir(confFS, ".")
	if err != nil {
		return err
	}
	for _, e := range entries {
		if e.IsDir() {
			continue
		}
		name := e.Name()
		embeddedNames[name] = true
		b, err := fs.ReadFile(confFS, name)
		if err != nil {
			return err
		}
		content := ienv.Expand(string(b))
		if name == "storage.conf" {
			content = injectAdditionalImageStores(content, stores)
		}
		if err := os.WriteFile(filepath.Join(configDir, name), []byte(content), 0o644); err != nil {
			return err
		}
	}

	// Per-file symlinks for everything else the tree carries (registries.conf,
	// policy.json, registries.conf.d/, ...), targeting the stable `current` path.
	treeConf := filepath.Join(current, "etc/containers")
	treeEntries, err := os.ReadDir(treeConf)
	if err != nil {
		if os.IsNotExist(err) {
			return nil
		}
		return err
	}
	for _, e := range treeEntries {
		name := e.Name()
		if embeddedNames[name] {
			continue
		}
		if err := forceSymlink(
			filepath.Join(treeConf, name),
			filepath.Join(configDir, name),
		); err != nil {
			return err
		}
	}
	return nil
}

// injectAdditionalImageStores rewrites storage.conf's additionalimagestores
// list to hold stores. The embedded file ships an empty list; when stores is
// empty the content is returned unchanged.
func injectAdditionalImageStores(content string, stores []string) string {
	if len(stores) == 0 {
		return content
	}
	lines := strings.Split(content, "\n")
	for i, l := range lines {
		if !strings.HasPrefix(strings.TrimSpace(l), "additionalimagestores") {
			continue
		}
		openIdx := strings.Index(l, "[")
		if openIdx < 0 {
			continue
		}
		// The closing bracket may be on this line (single-line list) or later.
		closeLine := i
		if !strings.Contains(l[openIdx:], "]") {
			for j := i + 1; j < len(lines); j++ {
				if strings.Contains(lines[j], "]") {
					closeLine = j
					break
				}
			}
		}
		var b strings.Builder
		b.WriteString(l[:openIdx+1]) // up to and including '['
		b.WriteByte('\n')
		for _, s := range stores {
			fmt.Fprintf(&b, "%q,\n", s)
		}
		b.WriteString("]")
		if tail := lines[closeLine]; strings.Contains(tail, "]") {
			b.WriteString(tail[strings.Index(tail, "]")+1:]) // preserve trailing text
		}

		out := make([]string, 0, len(lines))
		out = append(out, lines[:i]...)
		out = append(out, b.String())
		out = append(out, lines[closeLine+1:]...)
		return strings.Join(out, "\n")
	}
	return content
}
