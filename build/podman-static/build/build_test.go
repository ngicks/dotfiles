package build

import (
	"strings"
	"testing"
)

func TestBuildScript(t *testing.T) {
	s := buildScript("/mnt/psbuild")
	if !strings.Contains(s, `WORK="/mnt/psbuild"`) {
		t.Errorf("mount point not set:\n%s", s)
	}
	if !strings.Contains(s, "docker build --platform=linux/amd64 --output=type=local,dest=") {
		t.Errorf("docker build invocation missing:\n%s", s)
	}
	if !strings.Contains(s, "--target tar-archive") {
		t.Errorf("target stage missing:\n%s", s)
	}
	// The Lima docker template is rootless, so the script never needs sudo.
	if strings.Contains(s, "sudo") {
		t.Errorf("build script must not use sudo:\n%s", s)
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
