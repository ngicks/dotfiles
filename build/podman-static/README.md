# podman-static-dist

A single, CGO-free Go tool that **builds** a static [podman-static][upstream]
distribution (all binaries + my config) into one compressed tarball, and
**installs** it into `$HOME` on any machine.

It replaces the previous `build.sh` / `install.sh` / `copy_conf_interpolating.ts`
/ `insert_environment_file.ts` / `docker_install.sh` shell + deno scripts. Being
a static Go binary, install does not depend on `sed`, `envsubst`, `deno`, or any
other host tooling being present.

[upstream]: https://github.com/mgoltzsche/podman-static

## Commands

```
podman-static-dist build   -o <out.tar.zst> [-tag v5.8.4] [-recreate] [-yes] [VM flags]
podman-static-dist install -tar <out.tar.zst> [-tag v5.8.4]
```

Build the tool with (`build/podman-static/` is the module root; the resources
are embedded, so the binary is self-contained):

```sh
CGO_ENABLED=0 go build -o podman-static-dist .
```

### build

Builds inside a **Lima VM** so the result is reproducible and identical on Linux
and macOS hosts. Host requirements are [Lima][lima] 2.0+ (`limactl`) and `git`;
docker is provisioned *inside* the VM by Lima's `docker` template (rootless).

1. Ensures a persistent Lima instance (default `podman-static-build`) exists and
   is running, creating it from `template:docker` on first use. `-recreate`
   tears it down and rebuilds it fresh. You are prompted before a slow
   create/recreate unless `-yes` is given.
2. On the host: clones/checks out podman-static at `-tag` into the shared work
   dir (using the host's `git`, so the VM needs only docker).
3. Inside the VM: `make singlearch-tar PLATFORM=linux/amd64` against that
   checkout — upstream's Makefile builds the `tar-archive` image and assembles
   the whole `build/asset/podman-linux-amd64` tree (rootless docker, no sudo;
   `make` is provisioned into the VM, git is not needed there).
4. On the host (in Go): overlays the embedded `conf/` **un-interpolated** and
   stages the embedded `environment.d/` on top of that tree, then writes a
   **seekable** zstd tarball (`tar.Writer.AddFS` over a seekable-zstd writer) to
   the mandatory `-o` path.

The tag defaults to the embedded `resource/tag` (override with `-tag`). The
`conf`/`environment.d`/`tag` resources are baked into the binary at `go build`
time, so editing `resource/` requires a rebuild.

VM flags: `-vm-name` (Lima instance name) and `-work` (host dir shared with the
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

### install

Expands the tarball and wires it into your home — no container runtime or extra
tooling required:

- extracts to `${XDG_DATA_HOME:-$HOME/.local/share}/podman/<tag>`
  (or `$TARGET_ARTIFACT_DIR/<tag>`) — the seekable stream is read as an
  `io.ReaderAt`, presented as an `fs.FS` by `tarfs`, and materialized with
  `os.CopyFS`;
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

## Layout

`build/podman-static/` is the Go module root.

```
main.go                       thin flag entrypoint (std `flag`), delegates to services
resources.go                  //go:embed resource -> Conf/EnvironmentD/Tag (package main)
build/                        public pkg: orchestrates VM -> make singlearch-tar -> Overlay -> WriteArtifact
install/                      public pkg: ExtractArtifact -> interpolate -> systemd/symlink wiring
internal/buildpodman/         shared, exported building blocks used by build & install:
                              Overlay, WriteArtifact, ExtractArtifact,
                              InterpEnv/InterpolateTree, TransformUserUnitsInDir,
                              Sync (host-side git checkout of podman-static)
internal/lima/                Lima VM lifecycle + in-VM command execution (dns-provision.sh)
internal/cli/                 prompts
resource/                     embedded at build time (see resources.go)
  conf/                       config overlaid into etc/containers
  environment.d/              session env files linked into ~/.config/environment.d
  tag                         default podman-static tag to build/install
```

## Notes

- **Compression.** The artifact is a **seekable** zstd stream
  (`SaveTheRbtz/zstd-seekable-format-go` over klauspost/compress — both pure-Go,
  CGO-free). Encoding uses `SpeedBestCompression` (klauspost's ceiling, not a
  literal zstd level 20). tar output is batched into ~1 MiB frames, so the file
  is randomly seekable at a small size cost versus a plain stream.
- **Architecture.** The build targets `linux/amd64` (artifact
  `podman-linux-amd64`).
