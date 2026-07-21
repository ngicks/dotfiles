# nix2container Home Manager base

This is a hybrid build. nix2container emits the Home Manager-managed profile,
configuration, and package closure as reusable OCI layers. The Containerfile
uses that local image as its base and retains the imperative, network-dependent
parts of the existing build.

## Build

First build and load the Home Manager base into Podman. Its tag is derived with
the same `git describe` rule as the devenv image (`v0.0.82` becomes `0.0.82`):

```sh
./devenv/scripts/load-nix-home-manager-env.sh
```

Set `DEVENV_TAG` to load an experimental or otherwise explicit matching tag.

Then build the final release-tagged image:

```sh
devenv_tag=$(git describe --tags --abbrev=0)
devenv_tag=${devenv_tag#v}

podman buildx build . \
  --build-arg DEVENV_TAG="${devenv_tag}" \
  --build-arg GIT_TAG="${devenv_tag}" \
  --secret id=cert,src="${SSL_CERT_FILE:-/etc/ssl/certs/ca-certificates.crt}" \
  -f ./devenv/Containerfile \
  -t "localhost/devenv/devenv:${devenv_tag}"
```

For a working-tree build, use the same experimental tag for both images:

```sh
release_tag=$(git describe --tags --abbrev=0)
devenv_tag=${release_tag#v}-exp1
DEVENV_TAG="${devenv_tag}" ./devenv/scripts/load-nix-home-manager-env.sh

podman buildx build . \
  --build-arg DEVENV_TAG="${devenv_tag}" \
  --build-arg GIT_TAG=exp \
  --secret id=cert,src="${SSL_CERT_FILE:-/etc/ssl/certs/ca-certificates.crt}" \
  -f ./devenv/Containerfile \
  -t "localhost/devenv/devenv:${devenv_tag}"
```

Run it through the existing launcher:

```sh
./devenv_run.sh
```

The Containerfile accepts `BASE_IMAGE` if another base tag or registry is
needed:

```sh
podman buildx build . \
  --build-arg BASE_IMAGE=localhost/devenv/nix-home-manager-env:0.0.82 \
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
podman history localhost/devenv/nix-home-manager-env:0.0.82
podman image inspect localhost/devenv/nix-home-manager-env:0.0.82 \
  --format '{{.Size}}'
nix path-info -Sh ./nix-craft#devenv-home-base
time ./devenv/scripts/load-nix-home-manager-env.sh
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
