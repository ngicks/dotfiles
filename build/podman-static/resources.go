// Package resource embeds the build/install resource files — the config overlaid
// into the tree (conf/), the environment.d fragments, and the default tag — so
// the built tool is self-contained and needs no resource dir at runtime.
package resource

import (
	"embed"
	"io/fs"
	"strings"
)

//go:embed resource
var embedded embed.FS

// Conf is the config overlaid into etc/containers at build time (un-interpolated).
func Conf() (fs.FS, error) { return fs.Sub(embedded, "resource/conf") }

// EnvironmentD is the environment.d fragment linked into ~/.config/environment.d.
func EnvironmentD() (fs.FS, error) { return fs.Sub(embedded, "resource/environment.d") }

// Tag is the default podman-static tag to build/install.
func Tag() (string, error) {
	b, err := embedded.ReadFile("resource/tag")
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(string(b)), nil
}
