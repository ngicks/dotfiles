package commands

import (
	"github.com/spf13/cobra"

	"github.com/ngicks/podman-static-dist/pkg/podmanstaticdist"
)

const extractLong = `extract unpacks the .tar.zst artifact into the versioned dist dir
($TARGET_ARTIFACT_DIR/<tag>, else the config's artifact_dir/<tag>, else
${XDG_DATA_HOME:-$HOME/.local/share}/podman/<tag>) and interpolates the bundled
config against your environment. It leaves your home untouched: no symlinks are
created, no systemd wiring or daemon-reload is run.

Use install for the full flow (extract + symlink wiring) or link to wire an
already-extracted tree into your home.`

func extractCmd(parent *cobra.Command, flagConfig *string) {
	var (
		flagTar string
		flagTag string
	)

	cmd := &cobra.Command{
		Use:               "extract",
		Short:             "Unpack an artifact into the dist dir and interpolate config (no symlinks)",
		Long:              extractLong,
		Args:              cobra.NoArgs,
		ValidArgsFunction: cobra.NoFileCompletions,
		RunE: func(cmd *cobra.Command, args []string) error {
			return runExtract(cmd, args, *flagConfig, flagTar, flagTag)
		},
	}

	f := cmd.Flags()
	f.StringVar(&flagTar, "tar", "", "path to the .tar.zst artifact (required)")
	f.StringVar(&flagTag, "tag", "", "install tag / subdir name (default: config/embedded)")
	_ = cmd.MarkFlagRequired("tar")

	parent.AddCommand(cmd)
}

func runExtract(cmd *cobra.Command, _ []string, flagConfig, flagTar, flagTag string) error {
	cfg, err := podmanstaticdist.LoadConfig(flagConfig)
	if err != nil {
		return err
	}
	if cmd.Flags().Changed("tag") {
		cfg.Tag = flagTag
	}

	return podmanstaticdist.New(cfg).Extract(cmd.Context(), flagTar)
}
