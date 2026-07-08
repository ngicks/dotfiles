package cli

import (
	"encoding/json"
	"fmt"
	"io"
	"text/template"

	"github.com/ngicks/podman-static-dist/internal/templateutil"
	"github.com/ngicks/podman-static-dist/pkg/podmanstaticdist"
)

// TemplateFuncHelp returns the aligned help block for the helper functions
// available to a --format template, the same set every template renderer
// exposes. Command help embeds it so the docs cannot drift from
// templateutil.FuncMap.
func TemplateFuncHelp() string {
	return templateutil.FuncHelp()
}

// RenderConfig writes the resolved configuration to w.
//
// With format == "" it writes indented JSON. Otherwise format is parsed as a Go
// text/template and executed against cfg (field paths use the Go field names,
// e.g. {{.Tag}}); it sees the shared templateutil.FuncMap helpers (json, ...).
// Either form is terminated with a trailing newline. A malformed or failing
// template is returned as an error attributed to the --format flag.
func RenderConfig(w io.Writer, cfg podmanstaticdist.Config, format string) error {
	if format != "" {
		tmpl, err := template.New("config").
			Funcs(templateutil.FuncMap()).
			Parse(format)
		if err != nil {
			return fmt.Errorf("--format: %w", err)
		}
		if err := tmpl.Execute(w, cfg); err != nil {
			return fmt.Errorf("--format: %w", err)
		}
		fmt.Fprintln(w)
		return nil
	}

	b, err := json.MarshalIndent(cfg, "", "  ")
	if err != nil {
		return err
	}
	fmt.Fprintln(w, string(b))
	return nil
}
