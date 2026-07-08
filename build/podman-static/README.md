# podman-static-dist

A single, CGO-free Go tool that **builds** a static [podman-static][upstream]
distribution (all binaries + my config) into one compressed tarball, **installs**
it into `$HOME` on any machine, and **links** an already-extracted tree into a
container whose `$HOME` differs from the host.

It replaces the previous `build.sh` / `install.sh` / `copy_conf_interpolating.ts`
/ `insert_environment_file.ts` / `docker_install.sh` shell + deno scripts. Being
a static Go binary, install does not depend on `sed`, `envsubst`, `deno`, or any
other host tooling being present.

[upstream]: https://github.com/mgoltzsche/podman-static

## Commands

```
podman-static-dist build   -o <out.tar.zst> [--tag v5.8.4] [--recreate] [--yes] [VM flags]
podman-static-dist extract --tar <out.tar.zst> [--tag v5.8.4]
podman-static-dist install --tar <out.tar.zst> [--tag v5.8.4]
podman-static-dist link    [--base <dir>] [--tag <tag>] [--additional-image-store <path>]... [--skip-systemd]
podman-static-dist config  [--format <template>]
podman-static-dist version
```

The CLI is built on [cobra][cobra]; `--config` (persistent), `--log`, and
`--log-level` are available on every subcommand. Run any command with `--help`
for its full flag list.

Build the tool with (`build/podman-static/` is the module root; the resources
are embedded, so the binary is self-contained):

```sh
CGO_ENABLED=0 go build -o podman-static-dist ./cmd/podman-static-dist
```

[cobra]: https://github.com/spf13/cobra

### build

Builds inside a **Lima VM** so the result is reproducible and identical on Linux
and macOS hosts. Host requirements are [Lima][lima] 2.0+ (`limactl`) and `git`;
docker is provisioned *inside* the VM by Lima's `docker` template (rootless).

1. Ensures a persistent Lima instance (default `podman-static-build`) exists and
   is running, creating it from `template:docker` on first use. `--recreate`
   tears it down and rebuilds it fresh. You are prompted before a slow
   create/recreate unless `--yes` is given.
2. On the host: clones/checks out podman-static at `--tag` into the shared work
   dir (using the host's `git`, so the VM needs only docker).
3. Inside the VM: `make singlearch-tar PLATFORM=linux/amd64` against that
   checkout — upstream's Makefile builds the `tar-archive` image and assembles
   the whole `build/asset/podman-linux-amd64` tree (rootless docker, no sudo;
   `make` is provisioned into the VM, git is not needed there).
4. On the host (in Go): overlays the embedded `conf/` **un-interpolated** and
   stages the embedded `environment.d/` on top of that tree, then writes a
   **seekable** zstd tarball (`tar.Writer.AddFS` over a seekable-zstd writer) to
   the mandatory `-o`/`--output` path.

The tag resolves as `--tag` > config (`tag`) > embedded `resource/tag`; the VM
name resolves as `--vm-name` > config (`vm_name`) > lima's default. The
`conf`/`environment.d`/`tag` resources are baked into the binary at `go build`
time, so editing `resource/` requires a rebuild.

VM flags: `--vm-name` (Lima instance name) and `--work` (host dir shared with the
VM; defaults next to `-o`). The VM's shape is otherwise fixed internally, not a
user knob: it uses Lima's `docker` template, vCPUs match the host, disk is
`60GiB`, and memory is the lesser of `8GiB` or half the host's RAM. (These were
misleading as flags — a persistent instance keeps whatever size it was created
with and silently ignores a changed value on reuse.)

The VM is provisioned with a fixed DNS fix embedded from
`internal/lima/dns-provision.sh`: rootless docker runs `dockerd` in a
`gvisor-tap-vsock` network namespace that cannot reach systemd-resolved's
`127.0.0.53` stub, so the guest resolver is pointed at `1.1.1.1`/`8.8.8.8` for
image pulls. Edit that file if your network blocks those resolvers.

[lima]: https://lima-vm.io

### extract

Runs only the extract+interpolate phase of `install`: it unpacks the tarball into
the versioned dist dir and interpolates the bundled config against your
environment, but creates **no symlinks** and performs **no systemd wiring** (that
is `install` or `link`). Flags mirror `install`: `--tar` (required) and `--tag`
(resolved as `--tag` > config `tag` > embedded `resource/tag`); the dist dir
resolves the same way `install` does.

### install

Expands the tarball and wires it into your home — no container runtime or extra
tooling required:

- extracts to `$TARGET_ARTIFACT_DIR/<tag>` (else the config's `artifact_dir/<tag>`,
  else `${XDG_DATA_HOME:-$HOME/.local/share}/podman/<tag>`) — the seekable
  stream is read as an `io.ReaderAt`, presented as an `fs.FS` by `tarfs`, and
  materialized with `os.CopyFS`;
- **interpolates** the bundled config against your environment: only `${HOME}`
  and `${XDG_DATA_HOME}` are substituted (XDG_DATA_HOME synthesized when unset).
  `$XDG_RUNTIME_DIR`, `${PATH}`, and `${VAR:-default}` are intentionally left for
  session/runtime expansion;
- rewrites the systemd **user** units (inserts `EnvironmentFile=` and points the
  `podman` command at `~/.local/containers/bin/podman`);
- creates the symlinks `.../podman/current`, `~/.config/containers`,
  `~/.local/containers`, the per-unit links under `~/.config/systemd/user`, and
  the per-file `environment.d` links under `~/.config/environment.d`;
- registers the quadlet user generator in a system generator dir (directly when
  root, else via `sudo` with stdio forwarded; skipped with instructions when
  neither is available) and runs `systemctl --user daemon-reload`.

### link

Wires an **already-extracted** dist tree into your home without re-extracting it.
It is designed to run **inside the devenv container**, where the dist dir is a
**read-only mount** and `$HOME` differs from the host that produced the tree.

Because the host interpolated that tree against the host's `$HOME`, `link` does
**not** symlink `~/.config/containers` into the tree (that would leak host paths).
Instead it:

- force-symlinks `~/.local/containers` → `<base>/current/usr/local` (as install
  does);
- **materializes** `~/.config/containers` as a **real directory**: each embedded
  conf file (`containers.conf`, `storage.conf`, `path.env`, `path.sh`) is written
  interpolated against the **current** environment, and every other file under
  `<base>/current/etc/containers` (`registries.conf`, `policy.json`, …) is
  per-file symlinked. For `storage.conf`, `--additional-image-store` values are
  injected into the `additionalimagestores` list. Re-running overwrites the
  materialized files and relinks — it is idempotent;
- links the `environment.d` fragments per-file;
- performs the systemd wiring (unit links, quadlet generator, daemon-reload)
  unless `--skip-systemd` is given or `systemctl` is not on `PATH` (auto-skipped
  with a printed notice).

Flags:

- `--base <dir>` — dist base dir; defaults to `$TARGET_ARTIFACT_DIR`, else the
  config's `artifact_dir`, else `$XDG_DATA_HOME/podman`.
- `--tag <tag>` — when given **and** the base is writable, (re)points the `current`
  symlink at `<tag>`. A read-only base with an existing `current` is used as-is
  (never fails merely because it could not rewrite `current`). When omitted, the
  existing `current` symlink is used.
- `--additional-image-store <path>` — repeatable; also settable via config
  (`link.additional_image_stores`).
- `--skip-systemd` — skip the systemd wiring.

### config & version

- `config` prints the fully-resolved configuration (defaults < file < env) as
  indented JSON, or renders a Go `text/template` with `--format`/`-f`.
- `version` (also `--version`) prints the version and VCS build info.

## Configuration

Configuration is optional; every field has a default. The layering is
**defaults < config file < environment < explicit flags**.

| Field (JSON key)            | Env var                                          | Default                     | Used by               |
| --------------------------- | ------------------------------------------------ | --------------------------- | --------------------- |
| `tag`                       | `PODMAN_STATIC_DIST_TAG`                          | embedded `resource/tag`     | build/install/extract |
| `vm_name`                   | `PODMAN_STATIC_DIST_VM_NAME`                      | `podman-static-build`       | build                 |
| `artifact_dir`              | `PODMAN_STATIC_DIST_ARTIFACT_DIR`                 | *(unset)*                   | install/extract/link  |
| `link.additional_image_stores` | `PODMAN_STATIC_DIST_LINK_ADDITIONAL_IMAGE_STORES` | *(none)*                    | link                  |

The config file is **JSON**. Its path resolves as: `--config` flag, else
`$PODMAN_STATIC_DIST_CONF`, else
`os.UserConfigDir()/devenv/build/podman-static/config.json`. That default
deliberately differs from the project-name convention
(`UserConfigDir()/podman-static-dist`): the tool ships inside the devenv build
tree, so its config lives beside the other devenv build assets.

## Layout

`build/podman-static/` is the Go module root, in the canonical Cobra layout.

```
cmd/podman-static-dist/
  main.go                     signal wiring + process exit
  commands/                   thin cobra wiring (no business logic):
    root.go                     root cmd + Execute + runRoot
    build.go install.go link.go build/install/link subcommands
    version.go config.go        mandatory version + config subcommands
pkg/podmanstaticdist/          the service (usable without the CLI):
  version.go                    release-controlled const Version
  config.go                     Config/PartialConfig/Apply/LoadConfig (JSON)
  service.go                    Service (New): Config + per-call params -> build/install options,
                                owns tag/vm-name/artifact-dir/store defaults + env resolution
  build/                        orchestrates VM -> make singlearch-tar -> Overlay -> WriteArtifact
  install/                      ExtractArtifact -> interpolate -> systemd/symlink wiring; Link (container-safe)
  cli/                          CLI presentation: Confirm prompt, RenderConfig
resource/                      //go:embed conf/environment.d/tag -> Conf/EnvironmentD/Tag
  conf/                         config overlaid into etc/containers
  environment.d/                session env files linked into ~/.config/environment.d
  tag                           default podman-static tag to build/install
internal/buildpodman/          shared, exported building blocks used by build & install:
                               Overlay, WriteArtifact, ExtractArtifact,
                               InterpEnv/InterpolateTree, TransformUserUnitsInDir,
                               Sync (host-side git checkout of podman-static)
internal/lima/                 Lima VM lifecycle + in-VM command execution (dns-provision.sh)
internal/cmdsignals/           signal-cancellable root context
internal/loggerfactory/        --log / --log-level wiring
internal/versioninfo/          Version + VCS build info
internal/templateutil/         shared text/template FuncMap for config --format
internal/cmd/release/          cross-platform release helper (go run ./internal/cmd/release)
```

## Notes

- **Compression.** The artifact is a **seekable** zstd stream
  (`SaveTheRbtz/zstd-seekable-format-go` over klauspost/compress — both pure-Go,
  CGO-free). Encoding uses `SpeedBestCompression` (klauspost's ceiling, not a
  literal zstd level 20). tar output is batched into ~1 MiB frames, so the file
  is randomly seekable at a small size cost versus a plain stream.
- **Architecture.** The build targets `linux/amd64` (artifact
  `podman-linux-amd64`).
- **Releasing.** `go run ./internal/cmd/release vX.Y.Z` rewrites
  `pkg/podmanstaticdist/version.go`, commits, tags, and bumps to the next
  `-devel`.
