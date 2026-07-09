package podmanstaticdist

import (
	"context"

	"github.com/ngicks/podman-static-dist/pkg/podmanstaticdist/build"
	"github.com/ngicks/podman-static-dist/pkg/podmanstaticdist/install"
	"github.com/ngicks/podman-static-dist/rc"
)

type Service struct {
	cfg Config
}

func New(cfg Config) *Service {
	return &Service{cfg: cfg}
}

type BuildParams struct {
	OutputPath string
	Work       string
	Recreate   bool
	Confirm    func(prompt string) (bool, error)
}

func (s *Service) Build(ctx context.Context, p BuildParams) error {
	o, err := s.buildOption(p)
	if err != nil {
		return err
	}
	return build.Run(ctx, o)
}

func (s *Service) buildOption(p BuildParams) (build.Option, error) {
	o := build.Defaults()
	o.OutputPath = p.OutputPath
	o.Recreate = p.Recreate
	o.Confirm = p.Confirm
	o.Tag = s.cfg.Tag
	o.Vm.Name = s.cfg.VMName
	if p.Work != "" {
		o.Vm.HostWork = p.Work
	}
	o.Resource = rc.FS()
	return o, nil
}

func (s *Service) Install(ctx context.Context, tarPath, tag string) error {
	env, err := s.resolveEnv()
	if err != nil {
		return err
	}
	return install.Run(ctx, s.installOption(env, tarPath, tag))
}

func (s *Service) Extract(ctx context.Context, tarPath, tag string) error {
	env, err := s.resolveEnv()
	if err != nil {
		return err
	}
	return install.Extract(ctx, s.installOption(env, tarPath, tag))
}

// installOption carries the explicit --tag as Tag (empty when unset) and the
// config/embedded tag as the fallback, so install resolves --tag > archive stamp
// > config default.
func (s *Service) installOption(env install.Env, tarPath, tag string) install.Option {
	o := install.Defaults()
	o.TarPath = tarPath
	o.Tag = tag
	o.TagFallback = s.cfg.Tag
	o.Env = env
	return o
}

type LinkParams struct {
	Base        string
	Tag         string
	SkipSystemd bool
}

func (s *Service) Link(ctx context.Context, p LinkParams) error {
	env, err := s.resolveEnv()
	if err != nil {
		return err
	}
	return install.Link(ctx, install.LinkOption{
		Base:        p.Base,
		Tag:         p.Tag,
		SkipSystemd: p.SkipSystemd,
		Env:         env,
	})
}

func (s *Service) resolveEnv() (install.Env, error) {
	env, err := install.ResolveEnvFromOS()
	if err != nil {
		return install.Env{}, err
	}
	return s.withConfigArtifactDir(env), nil
}

func (s *Service) withConfigArtifactDir(env install.Env) install.Env {
	if env.ArtifactDir == "" && s.cfg.ArtifactDir != "" {
		env.ArtifactDir = s.cfg.ArtifactDir
	}
	return env
}
