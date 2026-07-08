// Package resource embeds the build/install resource files — the config
// overlaid into the tree (conf/), the environment.d fragments, and the default
// tag — so the tool is self-contained and needs no resource dir at runtime.
//
// Both the build and link subcommands read from here: build overlays conf/ into
// the distribution tree un-interpolated, while link materializes conf/ against
// the current environment inside the devenv container.
package resource

import (
	"embed"
	"io/fs"
	"strings"
)

//go:embed conf environment.d tag
var embedded embed.FS

// Conf is the config overlaid into etc/containers at build time
// (un-interpolated). link re-materializes these files against the current
// environment.
func Conf() (fs.FS, error) { return fs.Sub(embedded, "conf") }

// EnvironmentD is the environment.d fragment linked into ~/.config/environment.d.
func EnvironmentD() (fs.FS, error) { return fs.Sub(embedded, "environment.d") }

// Tag is the default podman-static tag to build/install.
func Tag() (string, error) {
	b, err := embedded.ReadFile("tag")
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(string(b)), nil
}

// DefaultTag is the embedded default podman-static tag. It panics only if the
// embedded tag file is unreadable, which cannot happen for a file baked in at
// compile time; use it where an error return is not warranted (e.g. config
// defaults).
func DefaultTag() string {
	tag, err := Tag()
	if err != nil {
		panic(err)
	}
	return tag
}
