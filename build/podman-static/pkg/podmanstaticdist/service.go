package podmanstaticdist

import (
	"context"
	"io/fs"

	"github.com/ngicks/podman-static-dist/pkg/podmanstaticdist/build"
	"github.com/ngicks/podman-static-dist/pkg/podmanstaticdist/install"
	"github.com/ngicks/podman-static-dist/resource"
)

// Service is the podman-static-dist service: it turns a resolved Config plus
// per-call parameters into the build/install packages' option structs and runs
// them. The CLI binary under ./cmd is thin wiring that loads a Config, overlays
// explicitly-set flags (flags win), constructs a Service, and calls one method —
// so every config-derived default (tag, VM name, artifact dir, link additional
// image stores) and every environment read lives here, not under ./cmd.
type Service struct {
	cfg Config
}

// New constructs a Service from an already-resolved Config (the merged
// defaults < file < env < flags result). Callers do not translate Config into
// the build/install options themselves; the service owns that.
func New(cfg Config) *Service {
	return &Service{cfg: cfg}
}

// BuildParams carries the per-invocation build inputs that are not
// config-derived. Tag and VM name come from the Config.
type BuildParams struct {
	// OutputPath is the destination .tar.zst (required).
	OutputPath string
	// Work is the host work dir shared with the VM; "" defaults next to OutputPath.
	Work string
	// Recreate tears down and rebuilds the Lima VM before building.
	Recreate bool
	// Confirm, when non-nil, is asked before provisioning a fresh (slow) VM; a
	// false return aborts. The CLI supplies a stdin/stderr prompt; nil skips the
	// prompt (the --yes path).
	Confirm func(prompt string) (bool, error)
}

// Build provisions the Lima VM, builds the distribution, and writes the
// artifact.
func (s *Service) Build(ctx context.Context, p BuildParams) error {
	o, err := s.buildOption(p)
	if err != nil {
		return err
	}
	return build.Run(ctx, o)
}

// buildOption translates the Config and per-call params into a build.Option. It
// is the pure translation step Build wraps, split out so it is unit-testable
// without provisioning a VM.
func (s *Service) buildOption(p BuildParams) (build.Option, error) {
	o := build.Defaults()
	o.OutputPath = p.OutputPath
	o.Recreate = p.Recreate
	o.Confirm = p.Confirm
	// Config values are assigned unconditionally: the merged Config is always
	// concrete (DefaultConfig seeds Tag and VMName), so an explicitly-set empty
	// value from a higher layer must win rather than be re-defaulted here.
	o.Tag = s.cfg.Tag
	o.Vm.Name = s.cfg.VMName
	if p.Work != "" {
		o.Vm.HostWork = p.Work
	}

	var err error
	if o.ConfFS, err = resource.Conf(); err != nil {
		return build.Option{}, err
	}
	if o.EnvFS, err = resource.EnvironmentD(); err != nil {
		return build.Option{}, err
	}
	return o, nil
}

// Install extracts the artifact and wires podman-static into the caller's home.
// The install tag comes from the Config; the dist base is resolved from the
// environment (TARGET_ARTIFACT_DIR), falling back to the configured artifact_dir.
func (s *Service) Install(ctx context.Context, tarPath string) error {
	env, err := s.resolveEnv()
	if err != nil {
		return err
	}
	return install.Run(ctx, s.installOption(env, tarPath))
}

// Extract runs only the extract+interpolate phase of Install (no symlinks, no
// systemd wiring).
func (s *Service) Extract(ctx context.Context, tarPath string) error {
	env, err := s.resolveEnv()
	if err != nil {
		return err
	}
	return install.Extract(ctx, s.installOption(env, tarPath))
}

// installOption translates the Config, resolved env, and tar path into an
// install.Option shared by Install and Extract.
func (s *Service) installOption(env install.Env, tarPath string) install.Option {
	o := install.Defaults()
	o.TarPath = tarPath
	o.Tag = s.cfg.Tag
	o.Env = env
	return o
}

// LinkParams carries the per-invocation link inputs that are not config-derived.
// The additional image stores come from the Config.
type LinkParams struct {
	// Base is the dist base dir; "" defaults to the resolved dist base.
	Base string
	// Tag, when set, (re)points the current symlink at it (only on a writable base).
	Tag string
	// SkipSystemd disables the systemd unit links, quadlet generator, and reload.
	SkipSystemd bool
}

// Link wires an already-extracted dist tree into the caller's home without
// re-extracting it (container-safe).
func (s *Service) Link(ctx context.Context, p LinkParams) error {
	env, err := s.resolveEnv()
	if err != nil {
		return err
	}
	confFS, err := resource.Conf()
	if err != nil {
		return err
	}
	return install.Link(ctx, s.linkOption(env, confFS, p))
}

// linkOption translates the Config, resolved env, embedded conf, and per-call
// params into an install.LinkOption.
func (s *Service) linkOption(env install.Env, confFS fs.FS, p LinkParams) install.LinkOption {
	return install.LinkOption{
		Base:                  p.Base,
		Tag:                   p.Tag,
		AdditionalImageStores: s.cfg.Link.AdditionalImageStores,
		SkipSystemd:           p.SkipSystemd,
		Env:                   env,
		ConfFS:                confFS,
	}
}

// resolveEnv reads the caller's environment (HOME, XDG paths,
// TARGET_ARTIFACT_DIR) and applies the configured artifact_dir as the dist base
// when TARGET_ARTIFACT_DIR is unset.
func (s *Service) resolveEnv() (install.Env, error) {
	env, err := install.ResolveEnvFromOS()
	if err != nil {
		return install.Env{}, err
	}
	return s.withConfigArtifactDir(env), nil
}

// withConfigArtifactDir fills env.ArtifactDir from the Config when the
// environment did not set TARGET_ARTIFACT_DIR — so TARGET_ARTIFACT_DIR wins over
// the configured artifact_dir.
func (s *Service) withConfigArtifactDir(env install.Env) install.Env {
	if env.ArtifactDir == "" && s.cfg.ArtifactDir != "" {
		env.ArtifactDir = s.cfg.ArtifactDir
	}
	return env
}
