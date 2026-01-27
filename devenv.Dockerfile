# syntax=docker/dockerfile:1

FROM docker.io/nixos/nix:2.33.1

ARG GIT_TAG=""
ARG HTTP_PROXY=""
ARG HTTPS_PROXY=""
ARG http_proxy=${HTTP_PROXY}
ARG https_proxy=${HTTPS_PROXY}
ARG NO_PROXY=""
ARG no_proxy=${NO_PROXY}

ARG SSL_CERT_FILE="/ca-certificates.crt"
ARG NODE_EXTRA_CA_CERTS=${SSL_CERT_FILE}
ARG DENO_CERT=${SSL_CERT_FILE}
ARG NIX_SSL_CERT_FILE=${SSL_CERT_FILE}

WORKDIR /root
RUN --mount=type=secret,id=cert,target=/ca-certificates.crt \
    --mount=type=bind,target=/.dotfiles \
<<EOF
    if [ "${GIT_TAG}" = "exp" ]; then
      cp -a /.dotfiles .
    else
      git clone --depth 1 --branch v${GIT_TAG} https://github.com/ngicks/dotfiles.git ./.dotfiles
    fi 
EOF

WORKDIR /root/.dotfiles

RUN --mount=type=secret,id=cert,target=/ca-certificates.crt \
<<EOF
    for p in $(nix-env -q); do
        nix-env --set-flag priority 0 $p
    done
    bash ./scripts/homeenv/nix-run-home-manager.sh
EOF

RUN <<EOF
    # Install nix-ld for FHS binary compatibility
    nix-env -iA nixpkgs.nix-ld

    # Create dynamic linker symlink (required for non-Nix binaries)
    mkdir -p /lib64 /lib
    NIX_LD_PATH=$(nix-build '<nixpkgs>' -A nix-ld --no-out-link)/libexec/nix-ld
    ln -sf ${NIX_LD_PATH} /lib64/ld-linux-x86-64.so.2
    ln -sf ${NIX_LD_PATH} /lib/ld-linux-x86-64.so.2
EOF

# Set library paths for FHS binary compatibility (general purpose)
ENV NIX_LD_LIBRARY_PATH="/root/.nix-profile/lib"

ENV SHELL="/root/.nix-profile/bin/zsh"
RUN <<EOF
    # For sshfs.nvim
    mkdir -p ~/mnt/sshfs

    mkdir -p "${XDG_CACHE_HOME:-/root/.cache}/dotfiles" && \
    touch "${XDG_CACHE_HOME:-/root/.cache}/dotfiles/.no_update_daily"
EOF


WORKDIR /root

ENV LANG=C.UTF-8

ENTRYPOINT ["/root/.nix-profile/bin/zsh"]
