// Command podman-static-dist builds and installs a static podman distribution.
//
// It is a thin entrypoint: it parses flags with the standard library `flag`
// package straight into each service's Option struct, validates, and delegates.
// The conf/environment.d/tag resources are embedded (see resources.go), so the
// binary is self-contained.
package main

import (
	"context"
	"errors"
	"flag"
	"fmt"
	"os"
	"os/signal"
	"syscall"

	"github.com/ngicks/podman-static-dist/build"
	"github.com/ngicks/podman-static-dist/install"
	"github.com/ngicks/podman-static-dist/internal/cli"
	"github.com/ngicks/podman-static-dist/internal/lima"
)

func main() {
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()
	if err := run(ctx, os.Args[1:]); err != nil {
		fmt.Fprintln(os.Stderr, "error:", err)
		os.Exit(1)
	}
}

func run(ctx context.Context, args []string) error {
	if len(args) == 0 {
		usage()
		return errors.New("expected a subcommand: build or install")
	}
	switch args[0] {
	case "build":
		return runBuild(ctx, args[1:])
	case "install":
		return runInstall(ctx, args[1:])
	case "-h", "--help", "help":
		usage()
		return nil
	default:
		usage()
		return fmt.Errorf("unknown subcommand %q", args[0])
	}
}

func runBuild(ctx context.Context, args []string) error {
	// Seed the VM defaults so the flags below bind directly onto them; an
	// unset flag keeps the default, a set flag overrides it.
	o := build.Option{Vm: lima.Defaults()}

	fs := flag.NewFlagSet("build", flag.ContinueOnError)
	fs.StringVar(&o.OutputPath, "o", "", "output .tar.zst path (required)")
	fs.StringVar(&o.Tag, "tag", "", "podman-static tag to build (default: embedded resource/tag)")
	fs.BoolVar(&o.Recreate, "recreate", false, "recreate the Lima VM before building")
	yes := fs.Bool("yes", false, "do not prompt before creating the VM")
	fs.StringVar(&o.Vm.Name, "vm-name", o.Vm.Name, "Lima instance name")
	fs.IntVar(&o.Vm.Cpus, "cpus", o.Vm.Cpus, "VM vCPUs")
	fs.StringVar(&o.Vm.Memory, "memory", o.Vm.Memory, "VM memory, e.g. 8GiB")
	fs.StringVar(&o.Vm.Disk, "disk", o.Vm.Disk, "VM disk, e.g. 60GiB")
	fs.StringVar(&o.Vm.HostWork, "work", o.Vm.HostWork, "host work dir shared with the VM")
	if err := fs.Parse(args); err != nil {
		return ignoreHelp(err)
	}

	tagVal, err := resolveTag(o.Tag)
	if err != nil {
		return err
	}
	o.Tag = tagVal
	if o.ConfFS, err = Conf(); err != nil {
		return err
	}
	if o.EnvFS, err = EnvironmentD(); err != nil {
		return err
	}
	if !*yes {
		o.Confirm = func(prompt string) (bool, error) {
			return cli.Confirm(os.Stdin, os.Stderr, prompt)
		}
	}
	return build.Run(ctx, o)
}

func runInstall(ctx context.Context, args []string) error {
	var o install.Option

	fs := flag.NewFlagSet("install", flag.ContinueOnError)
	fs.StringVar(&o.TarPath, "tar", "", "path to the .tar.zst artifact (required)")
	fs.StringVar(&o.Tag, "tag", "", "install tag / subdir name (default: embedded resource/tag)")
	if err := fs.Parse(args); err != nil {
		return ignoreHelp(err)
	}

	tagVal, err := resolveTag(o.Tag)
	if err != nil {
		return err
	}
	o.Tag = tagVal
	if o.Env, err = install.ResolveEnv(os.LookupEnv); err != nil {
		return err
	}
	return install.Run(ctx, o)
}

// resolveTag returns the -tag override if set, otherwise the embedded default.
func resolveTag(tag string) (string, error) {
	if tag != "" {
		return tag, nil
	}
	return Tag()
}

// ignoreHelp turns flag.ErrHelp (from -h) into a clean exit.
func ignoreHelp(err error) error {
	if errors.Is(err, flag.ErrHelp) {
		return nil
	}
	return err
}

func usage() {
	fmt.Fprint(os.Stderr, `podman-static-dist — build and install a static podman distribution

Usage:
  podman-static-dist build   -o <out.tar.zst> [-tag v5.8.4] [-recreate] [-yes] [VM flags]
  podman-static-dist install -tar <out.tar.zst> [-tag v5.8.4]

build   provisions a Lima VM (docker template), builds podman-static inside it,
        and writes a seekable zstd tar of all binaries plus conf (un-interpolated).
install expands the tar under XDG_DATA_HOME/podman/<tag> and wires it into your
        home, interpolating conf against your environment.

Resources (conf, environment.d, tag) are embedded; -tag overrides the default.

Run 'podman-static-dist build -h' or 'install -h' for the full flag list.
`)
}
