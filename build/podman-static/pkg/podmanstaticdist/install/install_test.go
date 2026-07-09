package install

import (
	"context"
	"os"
	"path/filepath"
	"testing"

	"github.com/ngicks/podman-static-dist/internal/buildpodman"
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

func TestExtractResolvesTag(t *testing.T) {
	newEnv := func(t *testing.T) (Env, string) {
		home := t.TempDir()
		base := t.TempDir()
		return Env{
			Home:        home,
			DataHome:    filepath.Join(home, ".local/share"),
			ConfigHome:  filepath.Join(home, ".config"),
			ArtifactDir: base,
		}, base
	}

	t.Run("empty option tag falls back to the archive stamp", func(t *testing.T) {
		env, base := newEnv(t)
		o := Option{TarPath: stampedArtifact(t, "v9.9.9"), Env: env}
		if err := Extract(context.Background(), o); err != nil {
			t.Fatal(err)
		}
		if _, err := os.Stat(filepath.Join(base, "v9.9.9", "tag")); err != nil {
			t.Errorf("expected extraction into <base>/v9.9.9: %v", err)
		}
	})

	t.Run("explicit option tag beats the archive stamp", func(t *testing.T) {
		env, base := newEnv(t)
		o := Option{TarPath: stampedArtifact(t, "v9.9.9"), Tag: "flag-tag", Env: env}
		if err := Extract(context.Background(), o); err != nil {
			t.Fatal(err)
		}
		if _, err := os.Stat(filepath.Join(base, "flag-tag", "tag")); err != nil {
			t.Errorf("expected extraction into <base>/flag-tag: %v", err)
		}
		if _, err := os.Stat(filepath.Join(base, "v9.9.9")); !os.IsNotExist(err) {
			t.Errorf("archive stamp should be ignored when --tag is set (err %v)", err)
		}
	})

	t.Run("config fallback fills in when neither flag nor stamp is present", func(t *testing.T) {
		env, base := newEnv(t)
		o := Option{TarPath: unstampedArtifact(t), TagFallback: "cfg-tag", Env: env}
		if err := Extract(context.Background(), o); err != nil {
			t.Fatal(err)
		}
		if _, err := os.Stat(filepath.Join(base, "cfg-tag")); err != nil {
			t.Errorf("expected extraction into <base>/cfg-tag: %v", err)
		}
	})

	t.Run("no tag anywhere is an error", func(t *testing.T) {
		env, _ := newEnv(t)
		o := Option{TarPath: unstampedArtifact(t), Env: env}
		if err := Extract(context.Background(), o); err == nil {
			t.Error("expected an error when no tag can be resolved")
		}
	})
}

func TestExtractAtomic(t *testing.T) {
	newEnv := func(t *testing.T) (Env, string) {
		home := t.TempDir()
		base := t.TempDir()
		return Env{
			Home:        home,
			DataHome:    filepath.Join(home, ".local/share"),
			ConfigHome:  filepath.Join(home, ".config"),
			ArtifactDir: base,
		}, base
	}

	t.Run("success leaves the dist dir complete and no tmp behind", func(t *testing.T) {
		env, base := newEnv(t)
		o := Option{TarPath: stampedArtifact(t, "v1"), Env: env}
		if err := Extract(context.Background(), o); err != nil {
			t.Fatal(err)
		}
		if _, err := os.Stat(filepath.Join(base, "v1", "tag")); err != nil {
			t.Errorf("dist dir incomplete after extract: %v", err)
		}
		if _, err := os.Stat(filepath.Join(base, "v1.tmp")); !os.IsNotExist(err) {
			t.Errorf("tmp dir survived a successful extract (err %v)", err)
		}
	})

	t.Run("corrupt archive leaves neither dist dir nor tmp", func(t *testing.T) {
		env, base := newEnv(t)
		o := Option{TarPath: corruptArtifact(t), Tag: "v1", Env: env}
		if err := Extract(context.Background(), o); err == nil {
			t.Fatal("expected an error extracting a corrupt archive")
		}
		if _, err := os.Stat(filepath.Join(base, "v1")); !os.IsNotExist(err) {
			t.Errorf("dist dir survived a failed extract (err %v)", err)
		}
		if _, err := os.Stat(filepath.Join(base, "v1.tmp")); !os.IsNotExist(err) {
			t.Errorf("tmp dir survived a failed extract (err %v)", err)
		}
	})

	t.Run("re-extract over an existing dist dir replaces it", func(t *testing.T) {
		env, base := newEnv(t)
		o := Option{TarPath: stampedArtifact(t, "v1"), Env: env}
		if err := Extract(context.Background(), o); err != nil {
			t.Fatal(err)
		}
		// A stray marker under the prior tree must not survive a replacing extract.
		stray := filepath.Join(base, "v1", "stray")
		writeTreeFile(t, stray, "x\n")
		if err := Extract(context.Background(), o); err != nil {
			t.Fatalf("re-extract: %v", err)
		}
		if _, err := os.Stat(filepath.Join(base, "v1", "tag")); err != nil {
			t.Errorf("dist dir incomplete after re-extract: %v", err)
		}
		if _, err := os.Stat(stray); !os.IsNotExist(err) {
			t.Errorf("stray file survived re-extract; replace was not clean (err %v)", err)
		}
		if _, err := os.Stat(filepath.Join(base, "v1.tmp")); !os.IsNotExist(err) {
			t.Errorf("tmp dir survived re-extract (err %v)", err)
		}
	})
}

// stampedArtifact writes a minimal dist tree carrying a root `tag` stamp and
// packs it as build does, returning the artifact path.
func stampedArtifact(t *testing.T, tag string) string {
	t.Helper()
	return packArtifact(t, tag)
}

// unstampedArtifact packs the same minimal tree without the `tag` stamp,
// standing in for an archive built before the stamp existed.
func unstampedArtifact(t *testing.T) string {
	t.Helper()
	return packArtifact(t, "")
}

// corruptArtifact writes garbage bytes in place of a real seekable-zstd archive
// so ExtractArtifact fails, exercising Extract's failure cleanup.
func corruptArtifact(t *testing.T) string {
	t.Helper()
	art := filepath.Join(t.TempDir(), "corrupt.tar.zst")
	if err := os.WriteFile(art, []byte("not a valid seekable zstd archive\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	return art
}

func packArtifact(t *testing.T, tag string) string {
	t.Helper()
	src := tupdateSymlink
	if tag != "" {
		writeTreeFile(t, filepath.Join(src, "tag"), tag+"\n")
	}
	// Extract interpolates etc/* and transforms usr/local/lib/systemd/user, so
	// those dirs must exist in the tree.
	writeTreeFile(
		t,
		filepath.Join(src, "etc/containers/storage.conf"),
		"graphroot = ${XDG_DATA_HOME}/g\n",
	)
	writeTreeFile(t, filepath.Join(src, "etc/environment.d/50-podman.conf"), "X=1\n")
	writeTreeFile(t, filepath.Join(src, "usr/local/lib/systemd/user/podman.service"), "[Service]\n")
	art := filepath.Join(t.TempDir(), "a.tar.zst")
	if err := buildpodman.WriteArtifact(src, art); err != nil {
		t.Fatal(err)
	}
	return art
}
