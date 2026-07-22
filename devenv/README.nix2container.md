# nix2container Home Manager base

This is a hybrid build. nix2container emits the Home Manager-managed profile,
configuration, and package closure as reusable OCI layers. The Containerfile
uses that local image as its base and retains the imperative, network-dependent
parts of the existing build.

## Build

`dotfilesmgr` (from `tool/dotfilesmgr`) drives both stages: it loads the Home
Manager base built by nix2container into Podman, then builds the final image on
top of it. Both images share a tag derived with the same `git describe` rule as
before (`v0.0.82` becomes `0.0.82`; experimental builds get an `-exp1` suffix).

```sh
dotfilesmgr standalone devenv build        # release build
dotfilesmgr standalone devenv build --exp  # working-tree (experimental) build
```

With a running `dotfilesmgr server serve`, submit the build as a job instead:

```sh
dotfilesmgr client devenv build [--exp] [--wait]
```

To load only the base image (e.g. for inspection), run the underlying command
directly:

```sh
nix run ./nix-craft#devenv-home-base.copyTo -- \
  "containers-storage:localhost/devenv/devenv-home-base:${tag}"
```

Run it through the existing launcher:

```sh
./devenv_run.sh
```

The Containerfile accepts `BASE_IMAGE` if another base tag or registry is
needed:

```sh
podman buildx build . \
  --build-arg BASE_IMAGE=localhost/devenv/devenv-home-base:0.0.82 \
  --build-arg GIT_TAG=exp \
  --secret id=cert,src="${SSL_CERT_FILE:-/etc/ssl/certs/ca-certificates.crt}" \
  -f ./devenv/Containerfile
```

## Boundary between the builders

The nix2container base provides:

- the Home Manager package closure and `/root/.nix-profile`;
- the Home Manager-managed files under `/root`;
- the shell, CA certificates, glibc compatibility links, user metadata, and
  other minimal root filesystem contents required by the Containerfile.

The Containerfile still:

- clones or copies `/root/.dotfiles`;
- creates runtime mountpoints and cache markers;
- installs the selected Rust toolchain with `rustup`;
- runs the MoonBit network installer;
- produces the final runnable image and tag.

There is deliberately no Nix database in the base. Home Manager is evaluated
and materialized by Nix before the image is emitted; the Containerfile must not
run `nix-env`, `nix-build`, or Home Manager activation.

## Layering

The Home Manager package closure is an explicit reusable layer group with up to
98 popularity-ranked layers. The smaller Home Manager file/root layer gets up
to two more layers. This keeps the image at no more than 100 generated layers
and, importantly, prevents a shell/editor configuration-only change from being
combined with the large package catch-all layer.

The verified split is approximately 12.365 GB across the package layer group
and 1.09 MB across the two Home Manager file/root layers. The package group
still has a roughly 12.02 GB catch-all, but Containerfile and configuration-only
changes no longer invalidate it.

This arrangement improves reuse; it does not reduce the total package closure.
The first measured closure was about 12.37 GB uncompressed. Its largest
individual paths included QEMU (~1.01 GB), Clang libraries (~0.85 GB),
`protoc-gen-es` (~0.84 GB), LLVM (~0.57 GB), Ansible (~0.54 GB), and Playwright
browsers (~1.1 GB combined).

Useful inspection commands:

```sh
podman history localhost/devenv/devenv-home-base:0.0.82
podman image inspect localhost/devenv/devenv-home-base:0.0.82 \
  --format '{{.Size}}'
nix path-info -Sh ./nix-craft#devenv-home-base
```

## Constraints and next improvements

1. A package-list change invalidates the Home Manager package layer group, but
   ordinary Containerfile, Rust, MoonBit, or repository changes do not.
2. `maxLayers` changes reuse granularity, not total size. Increasing it further
   trades a smaller catch-all for more OCI/storage-driver overhead.
3. Actual size reduction still requires a container-specific Home Manager
   package profile, with VM/GUI tools and optional browsers as likely first
   exclusions.
4. The base must be built natively for each Linux architecture before the
   Containerfile build. The current flake does not cross-build a Linux base from
   Darwin.
5. A registry workflow would let hosts pull the base rather than build it
   locally; that needs a tag/update policy separate from the final image.
