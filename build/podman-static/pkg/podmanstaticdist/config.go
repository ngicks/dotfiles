package podmanstaticdist

import (
	"encoding/json"
	"errors"
	"fmt"
	"io/fs"
	"os"
	"path/filepath"

	"github.com/caarlos0/env/v11"

	"github.com/ngicks/podman-static-dist/internal/lima"
	"github.com/ngicks/podman-static-dist/resource"
)

// Config is the materialized configuration the service consumes, after every
// layer (defaults < file < env < flags) is applied. Its fields are value types
// (the merged config is always concrete) and carry both json and yaml tags so the
// `config` subcommand can marshal it and a project can adopt either file format
// without touching fields. The file is NOT decoded into Config — PartialConfig is
// the decode target; Config only ever holds a fully-merged result.
type Config struct {
	// Tag is the podman-static tag to build/install.
	Tag string `json:"tag" yaml:"tag"`
	// VMName is the Lima instance name used by build.
	VMName string `json:"vm_name" yaml:"vm_name"`
	// ArtifactDir overrides the dist base dir for install/link.
	ArtifactDir string `json:"artifact_dir" yaml:"artifact_dir"`
	// Link is the link subcommand's sub-config (nested: deep-merged).
	Link LinkConfig `json:"link" yaml:"link"`
}

// LinkConfig is the link subcommand's sub-config.
type LinkConfig struct {
	// AdditionalImageStores are injected into storage.conf (slice: overwritten wholesale).
	AdditionalImageStores []string `json:"additional_image_stores" yaml:"additional_image_stores"`
}

// DefaultConfig is the lowest-precedence layer. The tag defaults to the embedded
// resource/tag and the VM name to lima's default, so a bare invocation still
// resolves both.
func DefaultConfig() Config {
	return Config{
		Tag:         resource.DefaultTag(),
		VMName:      lima.Defaults().Name,
		ArtifactDir: "",
		Link:        LinkConfig{AdditionalImageStores: nil},
	}
}

// PartialConfig is the exported sparse mirror of Config's serialized shape (the
// same keys): a nil/zero field means "absent, leave the lower layer"; a set field
// is an explicit value, including an explicit zero. It is the decode target for
// the config file (JSON) AND the struct LoadConfig fills via caarlos0/env, so file
// and env merge through one method, Apply. Exported so other code can build or
// inspect partial overrides.
//
// The PODMAN_STATIC_DIST_ prefix is applied once via envOptions, so the tags hold
// only the bare names (TAG -> PODMAN_STATIC_DIST_TAG, LINK_ + ADDITIONAL_IMAGE_STORES
// -> PODMAN_STATIC_DIST_LINK_ADDITIONAL_IMAGE_STORES).
//
//nolint:lll // triple json/yaml/env tags; one field per line, never wrap tags
type PartialConfig struct {
	Tag         *string           `json:"tag,omitzero" yaml:"tag,omitempty" env:"TAG"`
	VMName      *string           `json:"vm_name,omitzero" yaml:"vm_name,omitempty" env:"VM_NAME"`
	ArtifactDir *string           `json:"artifact_dir,omitzero" yaml:"artifact_dir,omitempty" env:"ARTIFACT_DIR"`
	Link        PartialLinkConfig `json:"link,omitzero" yaml:"link,omitempty" envPrefix:"LINK_"`
}

//nolint:lll // triple json/yaml/env tags; one field per line, never wrap tags
type PartialLinkConfig struct {
	AdditionalImageStores []string `json:"additional_image_stores,omitzero" yaml:"additional_image_stores,omitempty" env:"ADDITIONAL_IMAGE_STORES"`
}

// Apply overlays p's present fields onto base and returns the merged Config.
// Merge rules by field kind:
//   - scalar:        non-nil pointer overwrites (explicit zero included).
//   - nested struct: deep-merged via the sub-partial's Apply — always called; a
//     zero sub-partial (all fields nil) merges nothing.
//   - slice/array:   non-nil incoming slice overwrites wholesale (nil = leave base).
func (p PartialConfig) Apply(base Config) Config {
	if p.Tag != nil {
		base.Tag = *p.Tag
	}
	if p.VMName != nil {
		base.VMName = *p.VMName
	}
	if p.ArtifactDir != nil {
		base.ArtifactDir = *p.ArtifactDir
	}
	base.Link = p.Link.Apply(base.Link)
	return base
}

func (p PartialLinkConfig) Apply(base LinkConfig) LinkConfig {
	if p.AdditionalImageStores != nil {
		base.AdditionalImageStores = p.AdditionalImageStores
	}
	return base
}

// envOptions configures caarlos0/env for the env layer in LoadConfig. The
// variable names live in the env: / envPrefix: tags on PartialConfig; the
// PODMAN_STATIC_DIST_ prefix is applied here, yielding PODMAN_STATIC_DIST_TAG,
// PODMAN_STATIC_DIST_LINK_ADDITIONAL_IMAGE_STORES, etc.
var envOptions = env.Options{Prefix: "PODMAN_STATIC_DIST_"}

// LoadConfig assembles defaults < config file < environment through Apply. The
// ./cmd layer applies explicitly-set flags on top (flags win). flagPath is the
// --config value ("" when the flag is unset).
//
// The env layer fills a PartialConfig with caarlos0/env: a scalar/slice is set
// (non-nil) only when its variable is present; absent ones stay nil so Apply
// leaves the lower layer untouched. ParseWithOptions errors when a present value
// fails to parse — a hard error that aborts startup.
func LoadConfig(flagPath string) (Config, error) {
	cfg := DefaultConfig()

	path, err := configPath(flagPath)
	if err != nil {
		return cfg, err
	}
	filePartial, err := unmarshalConfigFile(path)
	if err != nil {
		return cfg, err
	}
	cfg = filePartial.Apply(cfg)

	var envPartial PartialConfig
	if err := env.ParseWithOptions(&envPartial, envOptions); err != nil {
		return cfg, err
	}
	cfg = envPartial.Apply(cfg)

	return cfg, nil
}

// unmarshalConfigFile only reads + decodes; it never merges. It decodes into a
// fresh zero PartialConfig (all nil) and returns the zero value when the file
// does not exist. A non-ENOENT read error or a JSON parse error aborts.
func unmarshalConfigFile(path string) (PartialConfig, error) {
	b, err := os.ReadFile(path)
	if err != nil {
		if errors.Is(err, fs.ErrNotExist) {
			return PartialConfig{}, nil
		}
		return PartialConfig{}, fmt.Errorf("read config %q: %w", path, err)
	}
	var p PartialConfig
	if err := json.Unmarshal(b, &p); err != nil {
		return PartialConfig{}, fmt.Errorf("parse config %q: %w", path, err)
	}
	return p, nil
}

// envConfVar names the config-file-path override. It is the one env var read by
// hand (the file path is needed before parsing, and is not a Config field); every
// other variable lives in PartialConfig's env tags.
const envConfVar = "PODMAN_STATIC_DIST_CONF"

// configPath resolves the file path: --config (flagPath), else $PODMAN_STATIC_DIST_CONF,
// else os.UserConfigDir()/devenv/build/podman-static/config.json.
//
// The default location deliberately diverges from the project-name convention
// (UserConfigDir()/podman-static-dist): this tool ships as part of the devenv
// build tree, so its config lives beside the other devenv build assets under
// devenv/build/podman-static.
func configPath(flagPath string) (string, error) {
	if flagPath != "" {
		return flagPath, nil
	}
	if p, ok := os.LookupEnv(envConfVar); ok {
		return p, nil
	}
	dir, err := os.UserConfigDir()
	if err != nil {
		return "", err
	}
	return filepath.Join(dir, "devenv", "build", "podman-static", "config.json"), nil
}
