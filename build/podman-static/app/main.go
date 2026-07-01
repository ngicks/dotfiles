// Command podman-static-dist builds and installs a static podman distribution.
//
// It is a thin entrypoint: it parses flags with the standard library `flag`
// package and delegates to the build/install services. The conf/environment.d/
// tag resources are embedded (see the resource package), so the binary is
// self-contained.
package main

import (
	"context"
	"errors"
	"flag"
	"fmt"
	"os"
	"os/signal"
	"syscall"

	resource "github.com/ngicks/podman-static-dist"
	"github.com/ngicks/podman-static-dist/internal/build"
	"github.com/ngicks/podman-static-dist/internal/cli"
	"github.com/ngicks/podman-static-dist/internal/install"
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
	fs := flag.NewFlagSet("build", flag.ContinueOnError)
	out := fs.String("o", "", "output .tar.zst path (required)")
	tag := fs.String("tag", "", "podman-static tag to build (default: embedded resource/tag)")
	recreate := fs.Bool("recreate", false, "recreate the Lima VM before building")
	yes := fs.Bool("yes", false, "do not prompt before creating the VM")
	vmName := fs.String("vm-name", "", "Lima instance name")
	cpus := fs.Int("cpus", 0, "VM vCPUs")
	memory := fs.String("memory", "", "VM memory, e.g. 8GiB")
	disk := fs.String("disk", "", "VM disk, e.g. 60GiB")
	work := fs.String("work", "", "host work dir shared with the VM")
	if err := fs.Parse(args); err != nil {
		return ignoreHelp(err)
	}
	if *out == "" {
		return errors.New("-o output path is required")
	}
	tagVal, err := resolveTag(*tag)
	if err != nil {
		return err
	}
	confFS, err := resource.Conf()
	if err != nil {
		return err
	}
	envFS, err := resource.EnvironmentD()
	if err != nil {
		return err
	}

	vm := lima.Defaults()
	if *vmName != "" {
		vm.Name = *vmName
	}
	if *cpus != 0 {
		vm.Cpus = *cpus
	}
	if *memory != "" {
		vm.Memory = *memory
	}
	if *disk != "" {
		vm.Disk = *disk
	}
	if *work != "" {
		vm.HostWork = *work
	}

	o := build.Options{
		Tag:        tagVal,
		ConfFS:     confFS,
		EnvFS:      envFS,
		OutputPath: *out,
		Recreate:   *recreate,
		Vm:         vm,
	}
	if !*yes {
		o.Confirm = func(prompt string) (bool, error) {
			return cli.Confirm(os.Stdin, os.Stderr, prompt)
		}
	}
	return build.Run(ctx, o)
}

func runInstall(ctx context.Context, args []string) error {
	fs := flag.NewFlagSet("install", flag.ContinueOnError)
	tarPath := fs.String("tar", "", "path to the .tar.zst artifact (required)")
	tag := fs.String("tag", "", "install tag / subdir name (default: embedded resource/tag)")
	if err := fs.Parse(args); err != nil {
		return ignoreHelp(err)
	}
	if *tarPath == "" {
		return errors.New("-tar path is required")
	}
	tagVal, err := resolveTag(*tag)
	if err != nil {
		return err
	}
	env, err := install.ResolveEnv(os.LookupEnv)
	if err != nil {
		return err
	}
	return install.Run(ctx, install.Options{TarPath: *tarPath, Tag: tagVal, Env: env})
}

// resolveTag returns the -tag override if set, otherwise the embedded default.
func resolveTag(tag string) (string, error) {
	if tag != "" {
		return tag, nil
	}
	return resource.Tag()
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
