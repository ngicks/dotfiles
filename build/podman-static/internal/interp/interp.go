// Package interp performs the install-time placeholder substitution for the
// bundled config files.
//
// It faithfully mirrors the previous copy_conf_interpolating.ts behavior: only
// ${HOME} and ${XDG_DATA_HOME} are replaced, using the caller's environment
// (requirement 6), synthesizing XDG_DATA_HOME as $HOME/.local/share when unset.
// Every other token ($XDG_RUNTIME_DIR, ${PATH}, ${VAR:-default}, shell locals)
// is intentionally left intact so it expands at session/runtime time as before.
package interp

import (
	"fmt"
	"strings"
)

// Env holds the values substituted into config files.
type Env struct {
	Home        string
	XdgDataHome string
}

// Resolve builds an Env from a lookup (typically os.LookupEnv), defaulting
// XDG_DATA_HOME to $HOME/.local/share when unset. HOME is required.
func Resolve(lookup func(string) (string, bool)) (Env, error) {
	home, ok := lookup("HOME")
	if !ok || home == "" {
		return Env{}, fmt.Errorf("environment variable HOME is not set")
	}
	xdg, ok := lookup("XDG_DATA_HOME")
	if !ok || xdg == "" {
		xdg = home + "/.local/share"
	}
	return Env{Home: home, XdgDataHome: xdg}, nil
}

// Expand replaces ${HOME} and ${XDG_DATA_HOME} in text. NewReplacer matches the
// exact braced tokens only, so bare $XDG_RUNTIME_DIR and defaulted
// ${XDG_DATA_HOME:-...} forms are left untouched.
func (e Env) Expand(text string) string {
	return strings.NewReplacer(
		"${HOME}", e.Home,
		"${XDG_DATA_HOME}", e.XdgDataHome,
	).Replace(text)
}
