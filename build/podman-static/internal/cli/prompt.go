// Package cli holds terminal presentation helpers (prompts, messages) kept out
// of the thin cmd entrypoint and the services.
package cli

import (
	"bufio"
	"fmt"
	"io"
	"strings"
)

// Confirm asks a yes/no question on out and reads the answer from in. The
// default (empty answer or EOF) is no.
func Confirm(in io.Reader, out io.Writer, prompt string) (bool, error) {
	if _, err := fmt.Fprintf(out, "%s [y/N]: ", prompt); err != nil {
		return false, err
	}
	sc := bufio.NewScanner(in)
	if !sc.Scan() {
		return false, sc.Err()
	}
	switch strings.ToLower(strings.TrimSpace(sc.Text())) {
	case "y", "yes":
		return true, nil
	default:
		return false, nil
	}
}
