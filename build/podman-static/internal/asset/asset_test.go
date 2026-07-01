package asset

import (
	"context"
	"os"
	"path/filepath"
	"testing"
)

func write(t *testing.T, path, content string, perm os.FileMode) {
	t.Helper()
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(path, []byte(content), perm); err != nil {
		t.Fatal(err)
	}
}

func TestAssemble(t *testing.T) {
	root := t.TempDir()
	rootfs := filepath.Join(root, "rootfs")
	repo := filepath.Join(root, "repo")
	conf := filepath.Join(root, "conf")
	envd := filepath.Join(root, "environment.d")
	dest := filepath.Join(root, "podman-linux-amd64")

	// exported image rootfs
	write(t, filepath.Join(rootfs, "etc/containers/containers.conf"), "# upstream\n", 0o644)
	write(t, filepath.Join(rootfs, "etc/containers/policy.json"), "{}\n", 0o644)
	write(t, filepath.Join(rootfs, "usr/local/bin/podman"), "bin\n", 0o755)
	write(t, filepath.Join(rootfs, "usr/local/lib/podman/conmon"), "conmon\n", 0o755)
	write(t, filepath.Join(rootfs, "usr/local/libexec/podman/quadlet"), "quadlet\n", 0o755)
	write(
		t,
		filepath.Join(rootfs, "usr/local/share/bash-completion/completions/podman"),
		"comp\n",
		0o644,
	)
	// note: no fish completions -> optional dir must be skipped, not error.

	// repo
	write(t, filepath.Join(repo, "README.md"), "readme\n", 0o644)
	for _, u := range systemdUnits {
		write(t, filepath.Join(repo, "conf/systemd", u), "[Unit]\n", 0o644)
	}

	// our conf (with placeholders that must survive un-interpolated)
	write(t, filepath.Join(conf, "containers.conf"), "conmon_path=[\"${HOME}/x\"]\n", 0o644)
	write(t, filepath.Join(conf, "storage.conf"), "graphroot = ${XDG_DATA_HOME}/g\n", 0o644)
	write(t, filepath.Join(conf, "path.sh"), "export PATH=\"$_c_bin:$PATH\"\n", 0o644)

	// our environment.d fragment
	write(t, filepath.Join(envd, "50-podman.conf"), "PODMAN=x\n", 0o644)

	if err := Assemble(
		context.Background(),
		Params{
			RootfsDir: rootfs,
			RepoDir:   repo,
			ConfFS:    os.DirFS(conf),
			EnvFS:     os.DirFS(envd),
			DestDir:   dest,
		},
	); err != nil {
		t.Fatalf("Assemble: %v", err)
	}

	// environment.d fragment delivered under usr/local/lib, un-interpolated
	if got := read(
		t,
		filepath.Join(dest, "usr/local/lib/environment.d/50-podman.conf"),
	); got != "PODMAN=x\n" {
		t.Errorf("environment.d fragment = %q", got)
	}

	// our conf overwrote upstream containers.conf, un-interpolated
	if got := read(
		t,
		filepath.Join(dest, "etc/containers/containers.conf"),
	); got != "conmon_path=[\"${HOME}/x\"]\n" {
		t.Errorf("containers.conf = %q; want our overlay with placeholder intact", got)
	}
	// storage.conf overlaid
	if got := read(
		t,
		filepath.Join(dest, "etc/containers/storage.conf"),
	); got != "graphroot = ${XDG_DATA_HOME}/g\n" {
		t.Errorf("storage.conf = %q", got)
	}
	// upstream file preserved
	if got := read(t, filepath.Join(dest, "etc/containers/policy.json")); got != "{}\n" {
		t.Errorf("policy.json = %q", got)
	}
	// binaries copied, exec bit preserved
	fi, err := os.Lstat(filepath.Join(dest, "usr/local/bin/podman"))
	if err != nil {
		t.Fatal(err)
	}
	if fi.Mode().Perm()&0o100 == 0 {
		t.Errorf("podman exec bit lost: %v", fi.Mode())
	}
	// systemd units in both scopes
	for _, scope := range []string{"system", "user"} {
		for _, u := range systemdUnits {
			if _, err := os.Stat(
				filepath.Join(dest, "usr/local/lib/systemd", scope, u),
			); err != nil {
				t.Errorf("missing systemd unit %s/%s: %v", scope, u, err)
			}
		}
	}
	// generator symlinks
	for _, gen := range []string{
		"usr/local/lib/systemd/system-generators/podman-system-generator",
		"usr/local/lib/systemd/user-generators/podman-user-generator",
	} {
		target, err := os.Readlink(filepath.Join(dest, gen))
		if err != nil {
			t.Errorf("Readlink %s: %v", gen, err)
			continue
		}
		if target != "../../../libexec/podman/quadlet" {
			t.Errorf("%s -> %q, want quadlet", gen, target)
		}
	}
	// README
	if got := read(t, filepath.Join(dest, "README.md")); got != "readme\n" {
		t.Errorf("README.md = %q", got)
	}
}

func read(t *testing.T, path string) string {
	t.Helper()
	b, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	return string(b)
}
