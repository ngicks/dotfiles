// Package install expands a build artifact and wires podman-static into the
// caller's home, replacing the previous install.sh + copy_conf_interpolating.ts
// + insert_environment_file.ts scripts.
//
// It extracts the tar.zst, interpolates the bundled config against the caller's
// environment (requirement 6, synthesizing XDG_DATA_HOME when unset), rewrites
// the systemd user units, and creates the symlinks, quadlet generator, and
// daemon-reload that the old install.sh performed.
package install

import (
	"context"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"

	"github.com/ngicks/podman-static-dist/internal/buildpodman"
)

// Env holds the caller's resolved environment. XDG paths are synthesized from
// HOME when unset (requirement 6).
type Env struct {
	Home        string // $HOME (required)
	DataHome    string // XDG_DATA_HOME, default $HOME/.local/share
	ConfigHome  string // XDG_CONFIG_HOME, default $HOME/.config
	ArtifactDir string // TARGET_ARTIFACT_DIR; overrides the podman base dir
}

// ResolveEnv builds an Env from a lookup (typically os.LookupEnv).
func ResolveEnv(lookup func(string) (string, bool)) (Env, error) {
	home, ok := lookup("HOME")
	if !ok || home == "" {
		return Env{}, fmt.Errorf("environment variable HOME is not set")
	}
	get := func(key, def string) string {
		if v, ok := lookup(key); ok && v != "" {
			return v
		}
		return def
	}
	return Env{
		Home:        home,
		DataHome:    get("XDG_DATA_HOME", filepath.Join(home, ".local/share")),
		ConfigHome:  get("XDG_CONFIG_HOME", filepath.Join(home, ".config")),
		ArtifactDir: get("TARGET_ARTIFACT_DIR", ""),
	}, nil
}

// podmanBase is the directory holding per-tag installs and the `current` link.
func (e Env) podmanBase() string {
	if e.ArtifactDir != "" {
		return e.ArtifactDir
	}
	return filepath.Join(e.DataHome, "podman")
}

// Option configures Run.
type Option struct {
	TarPath string // required: the .tar.zst produced by build
	Tag     string // required: version tag, used as the install subdir name
	Env     Env
}

// Defaults returns the base Option. Callers bind flags onto it and set Env (see
// ResolveEnv) before calling Run; install has no non-zero static defaults.
func Defaults() Option {
	return Option{}
}

// Validate reports whether the required fields are set. Run calls it before use.
func (o Option) Validate() error {
	if o.TarPath == "" {
		return fmt.Errorf("tar path is required")
	}
	if o.Tag == "" {
		return fmt.Errorf("tag is required")
	}
	if o.Env.Home == "" {
		return fmt.Errorf("env HOME is required")
	}
	return nil
}

// Run performs the full installation.
func Run(ctx context.Context, o Option) error {
	if err := o.Validate(); err != nil {
		return err
	}
	base := o.Env.podmanBase()
	builtDir := filepath.Join(base, o.Tag)

	if err := buildpodman.ExtractArtifact(o.TarPath, builtDir); err != nil {
		return fmt.Errorf("extracting %s: %w", o.TarPath, err)
	}

	ienv := buildpodman.InterpEnv{Home: o.Env.Home, XdgDataHome: o.Env.DataHome}
	if err := buildpodman.InterpolateTree(
		ctx,
		filepath.Join(builtDir, "etc/containers"),
		ienv,
	); err != nil {
		return fmt.Errorf("interpolating conf: %w", err)
	}

	envFile := filepath.Join(o.Env.ConfigHome, "containers/path.env")
	podmanPath := filepath.Join(o.Env.Home, ".local/containers/bin/podman")
	if err := buildpodman.TransformUserUnitsInDir(
		filepath.Join(builtDir, "usr/local/lib/systemd/user"),
		envFile,
		podmanPath,
	); err != nil {
		return fmt.Errorf("transforming user units: %w", err)
	}

	if err := wire(o.Env, base, builtDir, o.Tag); err != nil {
		return err
	}
	if err := installQuadletGenerator(ctx, o.Env); err != nil {
		return err
	}
	daemonReload(ctx)
	return nil
}

// wire creates the symlinks the old install.sh created: current -> tag,
// ~/.config/containers -> current/etc/containers, ~/.local/containers ->
// current/usr/local, one link per user systemd unit, and (new) one link per
// environment.d fragment.
func wire(env Env, base, builtDir, tag string) error {
	current := filepath.Join(base, "current")
	if err := replaceSymlink(tag, current); err != nil { // relative target, same dir
		return fmt.Errorf("linking current: %w", err)
	}
	if err := replaceSymlink(
		filepath.Join(current, "etc/containers"),
		filepath.Join(env.ConfigHome, "containers"),
	); err != nil {
		return fmt.Errorf("linking config dir: %w", err)
	}
	localContainers := filepath.Join(env.Home, ".local/containers")
	if err := replaceSymlink(filepath.Join(current, "usr/local"), localContainers); err != nil {
		return fmt.Errorf("linking local containers: %w", err)
	}

	// Per-file links into shared config dirs, targeting the stable
	// ~/.local/containers path so `current` re-pointing picks up new tags.
	if err := linkFiles(
		filepath.Join(builtDir, "usr/local/lib/systemd/user"),
		filepath.Join(env.ConfigHome, "systemd/user"),
		filepath.Join(localContainers, "lib/systemd/user"),
	); err != nil {
		return fmt.Errorf("linking user units: %w", err)
	}
	if err := linkFiles(
		filepath.Join(builtDir, "usr/local/lib/environment.d"),
		filepath.Join(env.ConfigHome, "environment.d"),
		filepath.Join(localContainers, "lib/environment.d"),
	); err != nil {
		return fmt.Errorf("linking environment.d: %w", err)
	}
	return nil
}

// linkFiles symlinks each regular file in srcDir into linkDir, each pointing at
// the matching name under targetBase. A missing srcDir is not an error (the
// tree may omit optional fragments); other files already in linkDir are left
// untouched.
func linkFiles(srcDir, linkDir, targetBase string) error {
	entries, err := os.ReadDir(srcDir)
	if err != nil {
		if os.IsNotExist(err) {
			return nil
		}
		return err
	}
	if err := os.MkdirAll(linkDir, 0o755); err != nil {
		return err
	}
	for _, e := range entries {
		if !e.Type().IsRegular() {
			continue
		}
		if err := forceSymlink(
			filepath.Join(targetBase, e.Name()),
			filepath.Join(linkDir, e.Name()),
		); err != nil {
			return err
		}
	}
	return nil
}

// installQuadletGenerator registers the quadlet user generator system-wide so
// systemd expands ~/.config/containers/systemd/*.container units. The generator
// must live in a system path (root-only), falling back to /run when /usr/local
// is not writable. When the installer is neither root nor able to sudo, this is
// skipped with instructions rather than failing: the binaries, conf and units
// are already in place, only quadlet auto-generation is deferred.
func installQuadletGenerator(ctx context.Context, env Env) error {
	quadlet := filepath.Join(env.Home, ".local/containers/libexec/podman/quadlet")
	if info, err := os.Stat(quadlet); err != nil || info.Mode()&0o111 == 0 {
		fmt.Fprintf(os.Stderr, "warning: quadlet binary not found or not executable: %s\n", quadlet)
		return nil
	}
	const genName = "podman-user-generator"
	primary := "/usr/local/lib/systemd/user-generators"
	if !canElevate() {
		fmt.Fprintf(os.Stderr,
			"warning: skipping quadlet generator (need root or sudo); to enable it, run as root:\n"+
				"  ln -sfn %s %s/%s\n", quadlet, primary, genName)
		return nil
	}
	if err := elevate(ctx, "mkdir", "-p", primary); err == nil {
		if err := elevate(ctx, "ln", "-sfn", quadlet, filepath.Join(primary, genName)); err != nil {
			return err
		}
		fmt.Printf("installed quadlet user generator: %s/%s\n", primary, genName)
		return nil
	}
	fallback := "/run/systemd/user-generators"
	if err := elevate(ctx, "mkdir", "-p", fallback); err != nil {
		return fmt.Errorf("creating quadlet generator dir: %w", err)
	}
	if err := elevate(ctx, "ln", "-sfn", quadlet, filepath.Join(fallback, genName)); err != nil {
		return err
	}
	fmt.Printf("installed quadlet user generator: %s/%s\n", fallback, genName)
	fmt.Fprintln(
		os.Stderr,
		"warning: /run is tmpfs; rerun this installer after reboot if the generator disappears",
	)
	return nil
}

// daemonReload reloads the user systemd manager; failure is non-fatal, matching
// the old `systemctl --user daemon-reload || true`.
func daemonReload(ctx context.Context) {
	cmd := exec.CommandContext(ctx, "systemctl", "--user", "daemon-reload")
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		fmt.Fprintf(os.Stderr, "warning: systemctl --user daemon-reload failed: %v\n", err)
	}
}

// replaceSymlink points linkPath at target, refusing to clobber a non-symlink
// (matches install.sh's safety check).
func replaceSymlink(target, linkPath string) error {
	if fi, err := os.Lstat(linkPath); err == nil {
		if fi.Mode()&os.ModeSymlink == 0 {
			return fmt.Errorf("refusing to replace non-symlink: %s", linkPath)
		}
		if err := os.Remove(linkPath); err != nil {
			return err
		}
	} else if !os.IsNotExist(err) {
		return err
	}
	if err := os.MkdirAll(filepath.Dir(linkPath), 0o755); err != nil {
		return err
	}
	return os.Symlink(target, linkPath)
}

// forceSymlink points linkPath at target, removing whatever is there first.
func forceSymlink(target, linkPath string) error {
	if err := os.Remove(linkPath); err != nil && !os.IsNotExist(err) {
		return err
	}
	if err := os.MkdirAll(filepath.Dir(linkPath), 0o755); err != nil {
		return err
	}
	return os.Symlink(target, linkPath)
}

// canElevate reports whether the installer can gain root: either it already is
// root, or a sudo binary is available to escalate.
func canElevate() bool {
	if os.Geteuid() == 0 {
		return true
	}
	_, err := exec.LookPath("sudo")
	return err == nil
}

// elevate runs a command with root privileges: directly when already root, via
// sudo otherwise. stdio is forwarded so a sudo password prompt reaches the user.
// Call only after canElevate reports true.
func elevate(ctx context.Context, name string, args ...string) error {
	argv := append([]string{name}, args...)
	if os.Geteuid() != 0 {
		argv = append([]string{"sudo"}, argv...)
	}
	cmd := exec.CommandContext(ctx, argv[0], argv[1:]...)
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}
