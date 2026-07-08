package install

import (
	"context"
	"io/fs"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"testing/fstest"
)

func TestInjectAdditionalImageStores(t *testing.T) {
	// Mirrors the embedded resource/conf/storage.conf shape: an empty list.
	const src = `[storage.options]
additionalimagestores = [
]

mountopt = "nodev"
`

	t.Run("empty stores leaves content unchanged", func(t *testing.T) {
		if got := injectAdditionalImageStores(src, nil); got != src {
			t.Errorf("expected unchanged content, got:\n%s", got)
		}
	})

	t.Run("injects each store as a quoted entry", func(t *testing.T) {
		got := injectAdditionalImageStores(src, []string{"/opt/store-a", "/opt/store-b"})
		for _, want := range []string{`"/opt/store-a",`, `"/opt/store-b",`} {
			if !strings.Contains(got, want) {
				t.Errorf("missing %q in:\n%s", want, got)
			}
		}
		// The surrounding structure must survive.
		if !strings.Contains(got, "additionalimagestores = [") || !strings.Contains(got, "]") {
			t.Errorf("list brackets lost:\n%s", got)
		}
		if !strings.Contains(got, `mountopt = "nodev"`) {
			t.Errorf("trailing content dropped:\n%s", got)
		}
		// The injected paths must sit inside the list, before the closing bracket.
		openIdx := strings.Index(got, "additionalimagestores = [")
		closeIdx := strings.Index(got[openIdx:], "\n]")
		storeIdx := strings.Index(got, `"/opt/store-a"`)
		if closeIdx < 0 || storeIdx < 0 || storeIdx > openIdx+closeIdx {
			t.Errorf("store not placed inside the list:\n%s", got)
		}
	})

	t.Run("single-line empty list", func(t *testing.T) {
		got := injectAdditionalImageStores("additionalimagestores = []\n", []string{"/x"})
		if !strings.Contains(got, `"/x",`) {
			t.Errorf("store not injected into single-line list:\n%s", got)
		}
	})
}

// writeTreeFile writes content at path, creating parent dirs.
func writeTreeFile(t *testing.T, path, content string) {
	t.Helper()
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(path, []byte(content), 0o644); err != nil {
		t.Fatal(err)
	}
}

// readTreeFile reads path or fails the test.
func readTreeFile(t *testing.T, path string) string {
	t.Helper()
	b, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	return string(b)
}

// assertRealFile asserts path exists and is a plain file (not a symlink).
func assertRealFile(t *testing.T, path string) {
	t.Helper()
	fi, err := os.Lstat(path)
	if err != nil {
		t.Fatalf("stat %s: %v", path, err)
	}
	if fi.Mode()&os.ModeSymlink != 0 {
		t.Errorf("%s is a symlink, want a real file", path)
	}
}

// linkFixture builds a fake extracted dist tree under a temp root and returns the
// base dir, the caller Env pointing at a sibling home, and an embedded conf FS.
//
// Layout (base/current -> v1, as wire creates the relative link):
//
//	base/v1/usr/local/bin/podman                          (tree binary)
//	base/v1/usr/local/lib/environment.d/50-podman.conf    (linked per-file)
//	base/v1/usr/local/lib/systemd/user/podman.socket      (systemd unit)
//	base/v1/etc/containers/storage.conf                   (embedded-named: NOT symlinked)
//	base/v1/etc/containers/registries.conf                (extra: per-file symlinked)
//	base/v1/etc/containers/policy.json                    (extra: per-file symlinked)
//
// The embedded confFS carries interpolation tokens so the materialized files can
// be asserted against the CURRENT environment, and a storage.conf with an empty
// additionalimagestores list for the injection assertion.
func linkFixture(t *testing.T) (base string, env Env, confFS fs.FS) {
	t.Helper()
	root := t.TempDir()
	base = filepath.Join(root, "base")
	home := filepath.Join(root, "home")
	tagDir := filepath.Join(base, "v1")

	writeTreeFile(t, filepath.Join(tagDir, "usr/local/bin/podman"), "binary\n")
	writeTreeFile(
		t,
		filepath.Join(tagDir, "usr/local/lib/environment.d/50-podman.conf"),
		"PODMAN=1\n",
	)
	writeTreeFile(
		t,
		filepath.Join(tagDir, "usr/local/lib/systemd/user/podman.socket"),
		"[Socket]\n",
	)

	// A host-interpolated storage.conf lives in the tree; it must be shadowed by
	// the materialized (current-env) copy, never symlinked in — its "/HOST/leak"
	// path must not surface in ~/.config/containers.
	writeTreeFile(t, filepath.Join(tagDir, "etc/containers/storage.conf"),
		"[storage.options]\nadditionalimagestores = [\n\"/HOST/leak\"\n]\n")
	writeTreeFile(t, filepath.Join(tagDir, "etc/containers/registries.conf"), "unqualified = []\n")
	writeTreeFile(t, filepath.Join(tagDir, "etc/containers/policy.json"), "{}\n")

	// current -> v1 (relative target, resolved against base), as wire creates it.
	if err := os.Symlink("v1", filepath.Join(base, "current")); err != nil {
		t.Fatal(err)
	}

	env = Env{
		Home:       home,
		DataHome:   filepath.Join(home, ".local/share"),
		ConfigHome: filepath.Join(home, ".config"),
	}
	confFS = fstest.MapFS{
		"containers.conf": &fstest.MapFile{
			Data: []byte("home = ${HOME}\ndata = ${XDG_DATA_HOME}\n"),
		},
		"storage.conf": &fstest.MapFile{
			Data: []byte("[storage.options]\nadditionalimagestores = [\n]\n"),
		},
		"path.env": &fstest.MapFile{Data: []byte("PATH=${HOME}/.local/containers/bin\n")},
	}
	return base, env, confFS
}

// assertWired verifies every effect Link's happy path must produce, so both the
// first run and the idempotent second run can reuse it.
func assertWired(t *testing.T, base string, env Env, stores []string) {
	t.Helper()
	current := filepath.Join(base, "current")
	localContainers := filepath.Join(env.Home, ".local/containers")
	configDir := filepath.Join(env.ConfigHome, "containers")

	// (a) ~/.local/containers -> current/usr/local.
	if got, err := os.Readlink(localContainers); err != nil ||
		got != filepath.Join(current, "usr/local") {
		t.Errorf("~/.local/containers link = %q (err %v), want %s",
			got, err, filepath.Join(current, "usr/local"))
	}

	// (b) ~/.config/containers is a real directory, not a symlink.
	fi, err := os.Lstat(configDir)
	if err != nil {
		t.Fatalf("stat config dir: %v", err)
	}
	if fi.Mode()&os.ModeSymlink != 0 || !fi.IsDir() {
		t.Errorf("~/.config/containers is not a real directory: mode %v", fi.Mode())
	}

	// containers.conf is materialized (real file) and interpolated against the
	// current environment.
	assertRealFile(t, filepath.Join(configDir, "containers.conf"))
	wantConf := "home = " + env.Home + "\ndata = " + env.DataHome + "\n"
	if got := readTreeFile(t, filepath.Join(configDir, "containers.conf")); got != wantConf {
		t.Errorf("containers.conf =\n%q\nwant\n%q", got, wantConf)
	}

	// storage.conf is materialized with the additional image stores injected, and
	// the host tree's copy did not leak in.
	assertRealFile(t, filepath.Join(configDir, "storage.conf"))
	gotStore := readTreeFile(t, filepath.Join(configDir, "storage.conf"))
	for _, s := range stores {
		if !strings.Contains(gotStore, `"`+s+`",`) {
			t.Errorf("storage.conf missing injected store %q:\n%s", s, gotStore)
		}
	}
	if strings.Contains(gotStore, "/HOST/leak") {
		t.Errorf("host storage.conf leaked into materialized copy:\n%s", gotStore)
	}

	// Non-embedded files are per-file symlinked, targeting the stable current path.
	for _, name := range []string{"registries.conf", "policy.json"} {
		want := filepath.Join(current, "etc/containers", name)
		if got, err := os.Readlink(filepath.Join(configDir, name)); err != nil || got != want {
			t.Errorf("%s link = %q (err %v), want %s", name, got, err, want)
		}
	}

	// environment.d is linked per-file (independent of --skip-systemd), targeting
	// the stable ~/.local/containers path.
	want := filepath.Join(localContainers, "lib/environment.d/50-podman.conf")
	envLink := filepath.Join(env.ConfigHome, "environment.d/50-podman.conf")
	if got, err := os.Readlink(envLink); err != nil || got != want {
		t.Errorf("environment.d link = %q (err %v), want %s", got, err, want)
	}
}

func TestLinkHappyPath(t *testing.T) {
	base, env, confFS := linkFixture(t)
	stores := []string{"/opt/store-a", "/opt/store-b"}
	o := LinkOption{
		Base:                  base,
		AdditionalImageStores: stores,
		SkipSystemd:           true, // keep the test independent of host systemctl.
		Env:                   env,
		ConfFS:                confFS,
	}
	if err := Link(context.Background(), o); err != nil {
		t.Fatalf("Link: %v", err)
	}
	assertWired(t, base, env, stores)
}

func TestLinkIdempotent(t *testing.T) {
	base, env, confFS := linkFixture(t)
	stores := []string{"/opt/store-a"}
	o := LinkOption{
		Base:                  base,
		AdditionalImageStores: stores,
		SkipSystemd:           true,
		Env:                   env,
		ConfFS:                confFS,
	}
	if err := Link(context.Background(), o); err != nil {
		t.Fatalf("first Link: %v", err)
	}
	if err := Link(context.Background(), o); err != nil {
		t.Fatalf("second Link: %v", err)
	}
	assertWired(t, base, env, stores)
}

func TestLinkReplacesPriorConfigSymlink(t *testing.T) {
	base, env, confFS := linkFixture(t)
	configDir := filepath.Join(env.ConfigHome, "containers")

	// Pre-create ~/.config/containers as a wholesale symlink (what the old Symlink
	// wired). Link must convert it to a real directory (link.go materializeConfigDir).
	if err := os.MkdirAll(filepath.Dir(configDir), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.Symlink(
		filepath.Join(base, "current/etc/containers"),
		configDir,
	); err != nil {
		t.Fatal(err)
	}
	if fi, err := os.Lstat(configDir); err != nil || fi.Mode()&os.ModeSymlink == 0 {
		t.Fatalf("precondition: config dir should be a symlink (err %v)", err)
	}

	o := LinkOption{
		Base:        base,
		SkipSystemd: true,
		Env:         env,
		ConfFS:      confFS,
	}
	if err := Link(context.Background(), o); err != nil {
		t.Fatalf("Link: %v", err)
	}

	fi, err := os.Lstat(configDir)
	if err != nil {
		t.Fatal(err)
	}
	if fi.Mode()&os.ModeSymlink != 0 || !fi.IsDir() {
		t.Errorf("prior symlink not converted to real dir: mode %v", fi.Mode())
	}
	assertWired(t, base, env, nil)
}

func TestLinkReadOnlyBaseTolerated(t *testing.T) {
	base, env, confFS := linkFixture(t)
	current := filepath.Join(base, "current")

	if err := os.Chmod(base, 0o555); err != nil {
		t.Fatal(err)
	}
	// Restore before t.TempDir's cleanup (LIFO) so the tree can be removed.
	t.Cleanup(func() { _ = os.Chmod(base, 0o755) })

	// chmod is ineffective under euid=0 (root bypasses dir perms). Probe the real
	// effect instead of the euid: if we can still create a file in base, the
	// read-only tolerance branch cannot be exercised here, so skip.
	probe := filepath.Join(base, ".probe")
	if f, err := os.Create(probe); err == nil {
		_ = f.Close()
		_ = os.Remove(probe)
		t.Skip("base writable despite chmod 0555 (running as root?); " +
			"read-only tolerance branch not exercised")
	}

	// --tag would repoint current on a writable base; on a read-only base the
	// rewrite fails but the existing current resolves, so Link tolerates it.
	o := LinkOption{
		Base:        base,
		Tag:         "v2",
		SkipSystemd: true,
		Env:         env,
		ConfFS:      confFS,
	}
	if err := Link(context.Background(), o); err != nil {
		t.Fatalf("read-only base with a valid current should be tolerated: %v", err)
	}
	// current is left as-is (still -> v1), not repointed to v2.
	if got, err := os.Readlink(current); err != nil || got != "v1" {
		t.Errorf("current = %q (err %v), want unchanged v1", got, err)
	}
	assertWired(t, base, env, nil)
}

func TestLinkMissingCurrentNoTag(t *testing.T) {
	root := t.TempDir()
	base := filepath.Join(root, "base")
	if err := os.MkdirAll(base, 0o755); err != nil {
		t.Fatal(err)
	}
	home := filepath.Join(root, "home")
	o := LinkOption{
		Base:        base, // no current symlink, and no --tag to create one.
		SkipSystemd: true,
		Env: Env{
			Home:       home,
			DataHome:   filepath.Join(home, ".local/share"),
			ConfigHome: filepath.Join(home, ".config"),
		},
		ConfFS: fstest.MapFS{
			"containers.conf": &fstest.MapFile{Data: []byte("x\n")},
		},
	}
	err := Link(context.Background(), o)
	if err == nil {
		t.Fatal("expected an error when current is missing and --tag is unset")
	}
	if !strings.Contains(err.Error(), "no current symlink") {
		t.Errorf("error = %v, want it to mention the missing current symlink", err)
	}
}

func TestLinkSkipSystemd(t *testing.T) {
	base, env, confFS := linkFixture(t)
	o := LinkOption{
		Base:        base,
		SkipSystemd: true,
		Env:         env,
		ConfFS:      confFS,
	}
	if err := Link(context.Background(), o); err != nil {
		t.Fatalf("Link: %v", err)
	}
	// environment.d is wired regardless of --skip-systemd.
	if _, err := os.Lstat(
		filepath.Join(env.ConfigHome, "environment.d/50-podman.conf"),
	); err != nil {
		t.Errorf("environment.d link missing under --skip-systemd: %v", err)
	}
	// systemd user units are NOT wired when skipped.
	if _, err := os.Lstat(
		filepath.Join(env.ConfigHome, "systemd/user/podman.socket"),
	); !os.IsNotExist(err) {
		t.Errorf("systemd user link created despite --skip-systemd (err %v)", err)
	}
}
