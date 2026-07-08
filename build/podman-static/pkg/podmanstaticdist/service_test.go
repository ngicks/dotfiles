package podmanstaticdist

import (
	"reflect"
	"testing"

	"github.com/ngicks/podman-static-dist/internal/lima"
	"github.com/ngicks/podman-static-dist/pkg/podmanstaticdist/build"
	"github.com/ngicks/podman-static-dist/pkg/podmanstaticdist/install"
	"github.com/ngicks/podman-static-dist/resource"
)

func TestServiceBuildOption(t *testing.T) {
	t.Run("config tag and vm name flow into the build option", func(t *testing.T) {
		o, err := New(Config{Tag: "cfg-tag", VMName: "cfg-vm"}).buildOption(BuildParams{
			OutputPath: "/out/podman.tar.zst",
			Work:       "/work",
			Recreate:   true,
		})
		if err != nil {
			t.Fatal(err)
		}
		if o.Tag != "cfg-tag" {
			t.Errorf("Tag = %q, want the config tag", o.Tag)
		}
		if o.Vm.Name != "cfg-vm" {
			t.Errorf("Vm.Name = %q, want the config vm name", o.Vm.Name)
		}
		if o.OutputPath != "/out/podman.tar.zst" {
			t.Errorf("OutputPath = %q", o.OutputPath)
		}
		if o.Vm.HostWork != "/work" {
			t.Errorf("Vm.HostWork = %q, want the per-call work dir", o.Vm.HostWork)
		}
		if !o.Recreate {
			t.Error("Recreate not carried through")
		}
		if o.ConfFS == nil || o.EnvFS == nil {
			t.Error("embedded resources not attached")
		}
	})

	t.Run(
		"explicit empty Tag and VMName propagate to the build option verbatim",
		func(t *testing.T) {
			// After LoadConfig the Config is always concrete, so an explicit empty
			// value (e.g. --vm-name "") is a deliberate override that must win — the
			// service no longer re-defaults it to build/lima's baked value.
			o, err := New(Config{Tag: "", VMName: ""}).buildOption(BuildParams{OutputPath: "/out"})
			if err != nil {
				t.Fatal(err)
			}
			if o.Tag != "" {
				t.Errorf("Tag = %q, want the explicit empty config tag", o.Tag)
			}
			if o.Vm.Name != "" {
				t.Errorf("Vm.Name = %q, want the explicit empty config vm name", o.Vm.Name)
			}
		},
	)

	t.Run("DefaultConfig values flow through to the build option", func(t *testing.T) {
		o, err := New(DefaultConfig()).buildOption(BuildParams{OutputPath: "/out"})
		if err != nil {
			t.Fatal(err)
		}
		if o.Tag != resource.DefaultTag() {
			t.Errorf("Tag = %q, want the embedded default tag %q", o.Tag, resource.DefaultTag())
		}
		if o.Vm.Name != lima.Defaults().Name {
			t.Errorf("Vm.Name = %q, want the lima default %q", o.Vm.Name, lima.Defaults().Name)
		}
	})

	t.Run("empty per-call work falls back to the build default", func(t *testing.T) {
		o, err := New(DefaultConfig()).buildOption(BuildParams{OutputPath: "/out"})
		if err != nil {
			t.Fatal(err)
		}
		// Work is a per-call param (not a Config field); "" means "default next to
		// OutputPath", resolved by build.Run, so buildOption leaves it at the base.
		if o.Vm.HostWork != build.Defaults().Vm.HostWork {
			t.Errorf(
				"Vm.HostWork = %q, want the build default %q",
				o.Vm.HostWork,
				build.Defaults().Vm.HostWork,
			)
		}
	})
}

func TestServiceInstallOption(t *testing.T) {
	env := install.Env{
		Home:       "/home/u",
		DataHome:   "/home/u/.local/share",
		ConfigHome: "/home/u/.config",
	}
	o := New(Config{Tag: "cfg-tag"}).installOption(env, "/art/podman.tar.zst")
	if o.Tag != "cfg-tag" {
		t.Errorf("Tag = %q, want the config tag", o.Tag)
	}
	if o.TarPath != "/art/podman.tar.zst" {
		t.Errorf("TarPath = %q", o.TarPath)
	}
	if o.Env != env {
		t.Errorf("Env = %+v, want %+v", o.Env, env)
	}

	// An explicit empty Tag propagates verbatim (installOption assigns
	// unconditionally, matching buildOption's flags-win semantics).
	if got := New(Config{Tag: ""}).installOption(env, "/art/podman.tar.zst"); got.Tag != "" {
		t.Errorf("Tag = %q, want the explicit empty config tag to propagate", got.Tag)
	}
}

func TestServiceArtifactDirPrecedence(t *testing.T) {
	svc := New(Config{ArtifactDir: "/cfg/artifact"})

	t.Run("env TARGET_ARTIFACT_DIR wins over config artifact_dir", func(t *testing.T) {
		got := svc.withConfigArtifactDir(install.Env{ArtifactDir: "/env/artifact"})
		if got.ArtifactDir != "/env/artifact" {
			t.Errorf("ArtifactDir = %q, want the env value to win", got.ArtifactDir)
		}
	})

	t.Run("config artifact_dir fills in when env is unset", func(t *testing.T) {
		got := svc.withConfigArtifactDir(install.Env{})
		if got.ArtifactDir != "/cfg/artifact" {
			t.Errorf("ArtifactDir = %q, want the config value", got.ArtifactDir)
		}
	})

	t.Run("neither set leaves it empty", func(t *testing.T) {
		got := New(Config{}).withConfigArtifactDir(install.Env{})
		if got.ArtifactDir != "" {
			t.Errorf("ArtifactDir = %q, want empty", got.ArtifactDir)
		}
	})
}

func TestServiceLinkOption(t *testing.T) {
	confFS, err := resource.Conf()
	if err != nil {
		t.Fatal(err)
	}
	env := install.Env{Home: "/home/u"}
	o := New(Config{
		Link: LinkConfig{AdditionalImageStores: []string{"/s1", "/s2"}},
	}).linkOption(env, confFS, LinkParams{
		Base:        "/base",
		Tag:         "v1",
		SkipSystemd: true,
	})
	if !reflect.DeepEqual(o.AdditionalImageStores, []string{"/s1", "/s2"}) {
		t.Errorf("AdditionalImageStores = %v, want the config slice", o.AdditionalImageStores)
	}
	if o.Base != "/base" || o.Tag != "v1" || !o.SkipSystemd {
		t.Errorf("per-call params not carried: %+v", o)
	}
	if o.Env != env {
		t.Errorf("Env = %+v, want %+v", o.Env, env)
	}
	if o.ConfFS == nil {
		t.Error("ConfFS not attached")
	}
}
