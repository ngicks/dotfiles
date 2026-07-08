package install

import (
	"os"
	"path/filepath"
	"testing"
)

func TestResolveEnvDefaults(t *testing.T) {
	env, err := ResolveEnv(func(k string) (string, bool) {
		if k == "HOME" {
			return "/home/u", true
		}
		return "", false
	})
	if err != nil {
		t.Fatal(err)
	}
	if env.DataHome != "/home/u/.local/share" || env.ConfigHome != "/home/u/.config" {
		t.Errorf("defaults wrong: %+v", env)
	}
	if env.podmanBase() != "/home/u/.local/share/podman" {
		t.Errorf("podmanBase = %q", env.podmanBase())
	}
}

func TestResolveEnvArtifactDirOverride(t *testing.T) {
	env, err := ResolveEnv(func(k string) (string, bool) {
		switch k {
		case "HOME":
			return "/home/u", true
		case "TARGET_ARTIFACT_DIR":
			return "/opt/podman", true
		}
		return "", false
	})
	if err != nil {
		t.Fatal(err)
	}
	if env.podmanBase() != "/opt/podman" {
		t.Errorf("podmanBase = %q, want override", env.podmanBase())
	}
}

func TestLinkFiles(t *testing.T) {
	root := t.TempDir()
	src := filepath.Join(root, "src")
	if err := os.MkdirAll(src, 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(
		filepath.Join(src, "50-podman.conf"),
		[]byte("X=1\n"),
		0o644,
	); err != nil {
		t.Fatal(err)
	}
	linkDir := filepath.Join(root, "cfg/environment.d")
	if err := os.MkdirAll(linkDir, 0o755); err != nil {
		t.Fatal(err)
	}
	// a fragment from another source (e.g. the dotfiles) must survive.
	other := filepath.Join(linkDir, "75-other.conf")
	if err := os.WriteFile(other, []byte("Y=2\n"), 0o644); err != nil {
		t.Fatal(err)
	}

	if err := linkFiles(src, linkDir, "/base/lib/environment.d"); err != nil {
		t.Fatal(err)
	}
	got, err := os.Readlink(filepath.Join(linkDir, "50-podman.conf"))
	if err != nil {
		t.Fatalf("expected a symlink: %v", err)
	}
	if got != "/base/lib/environment.d/50-podman.conf" {
		t.Errorf("link target = %q", got)
	}
	if _, err := os.Lstat(other); err != nil {
		t.Errorf("unrelated fragment was removed: %v", err)
	}

	// A missing srcDir is a no-op, not an error.
	if err := linkFiles(filepath.Join(root, "absent"), linkDir, "/base"); err != nil {
		t.Errorf("missing srcDir should be a no-op, got %v", err)
	}
}
