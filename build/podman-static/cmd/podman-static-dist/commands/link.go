package commands

import (
	"github.com/spf13/cobra"

	"github.com/ngicks/podman-static-dist/pkg/podmanstaticdist"
)

const linkLong = `link wires an already-extracted dist tree into your home without re-extracting
it. It is meant to run inside the devenv container, where the dist dir is a
READ-ONLY mount and $HOME differs from the host that produced the tree.

Because the host interpolated the tree against its own $HOME, link does NOT
symlink ~/.config/containers into the tree. Instead it materializes
~/.config/containers as a real directory: the bundled conf (containers.conf,
storage.conf, path.env, path.sh) is rewritten against the CURRENT environment,
and every other file under <base>/current/etc/containers is per-file symlinked.
Re-running overwrites the materialized files and relinks — it is idempotent.

The base dir defaults to $TARGET_ARTIFACT_DIR, else the config's artifact_dir,
else $XDG_DATA_HOME/podman. The current symlink is only created/updated when
--tag is given AND the base is writable; a read-only base with an existing
current symlink is used as-is.`

func linkCmd(parent *cobra.Command, flagConfig *string) {
	var (
		flagBase        string
		flagTag         string
		flagStores      []string
		flagSkipSystemd bool
	)

	cmd := &cobra.Command{
		Use:               "link",
		Short:             "Wire an already-extracted dist tree into your home (read-only mount safe)",
		Long:              linkLong,
		Args:              cobra.NoArgs,
		ValidArgsFunction: cobra.NoFileCompletions,
		RunE: func(cmd *cobra.Command, args []string) error {
			return runLink(cmd, args, *flagConfig, flagBase, flagTag, flagStores, flagSkipSystemd)
		},
	}

	f := cmd.Flags()
	f.StringVar(&flagBase, "base", "", "dist base directory")
	f.StringVar(&flagTag, "tag", "", "tag for the current symlink")
	f.StringArrayVar(
		&flagStores,
		"additional-image-store",
		nil,
		"extra read-only image store (repeatable)",
	)
	f.BoolVar(&flagSkipSystemd, "skip-systemd", false, "skip systemd wiring")

	parent.AddCommand(cmd)
}

func runLink(
	cmd *cobra.Command, _ []string, flagConfig,
	flagBase, flagTag string, flagStores []string, flagSkipSystemd bool,
) error {
	cfg, err := podmanstaticdist.LoadConfig(flagConfig)
	if err != nil {
		return err
	}
	if cmd.Flags().Changed("additional-image-store") {
		cfg.Link.AdditionalImageStores = flagStores
	}

	return podmanstaticdist.New(cfg).Link(cmd.Context(), podmanstaticdist.LinkParams{
		Base:        flagBase,
		Tag:         flagTag,
		SkipSystemd: flagSkipSystemd,
	})
}
