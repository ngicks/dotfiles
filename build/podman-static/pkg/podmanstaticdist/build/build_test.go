package build

import (
	"path/filepath"
	"strings"
	"testing"
	"testing/fstest"

	"github.com/ngicks/podman-static-dist/internal/lima"
)

func TestOptionValidate(t *testing.T) {
	valid := Option{
		Tag:        "v5.8.4",
		ConfFS:     fstest.MapFS{},
		OutputPath: "/out/podman.tar.zst",
		Vm:         lima.Config{Name: "podman-static-build"},
	}
	if err := valid.Validate(); err != nil {
		t.Errorf("valid option rejected: %v", err)
	}

	cases := []struct {
		name   string
		mutate func(*Option)
	}{
		{"empty tag", func(o *Option) { o.Tag = "" }},
		{"nil conf fs", func(o *Option) { o.ConfFS = nil }},
		{"empty output path", func(o *Option) { o.OutputPath = "" }},
		// An empty VM name is rejected rather than silently re-defaulted: the
		// merged config always seeds vm_name, so "" is a deliberate override.
		{"empty vm name", func(o *Option) { o.Vm.Name = "" }},
	}
	for _, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			o := valid
			c.mutate(&o)
			if err := o.Validate(); err == nil {
				t.Errorf("Validate accepted %s", c.name)
			}
		})
	}
}

func TestBuildScript(t *testing.T) {
	s := buildScript("/mnt/psbuild/podman-static")
	if !strings.Contains(s, "cd \"/mnt/psbuild/podman-static\"") {
		t.Errorf("repo path not set:\n%s", s)
	}
	// The build delegates the whole layout to upstream's Makefile.
	if !strings.Contains(s, "make singlearch-tar") {
		t.Errorf("make singlearch-tar invocation missing:\n%s", s)
	}
	if !strings.Contains(s, "make create-builder") {
		t.Errorf("buildx builder creation missing:\n%s", s)
	}
	// make is not in the docker template, so the script installs it on demand.
	if !strings.Contains(s, "install -y make") {
		t.Errorf("make install fallback missing:\n%s", s)
	}
	// git runs on the host now; the in-VM script must not need it.
	if strings.Contains(s, "git ") {
		t.Errorf("build script must not run git in the VM:\n%s", s)
	}
}

func TestDefaultHostWork(t *testing.T) {
	got := defaultHostWork("/home/u/out/podman.tar.zst")
	if got != "/home/u/out/.podman-static-build" {
		t.Errorf("defaultHostWork = %q", got)
	}
}

func TestSameDir(t *testing.T) {
	cwd, err := filepath.Abs(".")
	if err != nil {
		t.Fatal(err)
	}
	cases := []struct {
		a, b string
		want bool
	}{
		{"/a/b", "/a/b", true},
		{"/a/b/", "/a/b", true},     // trailing slash
		{"/a/b/../b", "/a/b", true}, // cleaned
		{"/a/b", "/a/c", false},     // different
		{"x/y", cwd + "/x/y", true}, // relative resolves against cwd
	}
	for _, c := range cases {
		if got := sameDir(c.a, c.b); got != c.want {
			t.Errorf("sameDir(%q, %q) = %v, want %v", c.a, c.b, got, c.want)
		}
	}
}
