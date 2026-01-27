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

WORKDIR /root/.dotfiles
RUN --mount=type=secret,id=cert,target=/ca-certificates.crt \
<<EOF
    git clone --depth 1 --branch v${GIT_TAG} https://github.com/ngicks/dotfiles.git .
EOF

RUN --mount=type=secret,id=cert,target=/ca-certificates.crt \
<<EOF
    for p in $(nix-env -q); do
        nix-env --set-flag priority 0 $p
    done
    bash ./scripts/homeenv/nix-run-home-manager.sh
EOF

ENV SHELL="/root/.nix-profile/bin/zsh"
RUN <<EOF
    # For sshfs.nvim
    mkdir -p ~/mnt/sshfs

    mkdir -p "${XDG_CACHE_HOME:-/root/.cache}/dotfiles" && \
    touch "${XDG_CACHE_HOME:-/root/.cache}/dotfiles/.no_update_daily"

    # FHS compatibility: Create dynamic linker symlinks for non-Nix binaries
    mkdir -p /lib64 /lib
    GLIBC_PATH=$(nix-build '<nixpkgs>' -A glibc --no-out-link)
    ln -sf ${GLIBC_PATH}/lib/ld-linux-x86-64.so.2 /lib64/ld-linux-x86-64.so.2
    ln -sf ${GLIBC_PATH}/lib/ld-linux-x86-64.so.2 /lib/ld-linux-x86-64.so.2
EOF


WORKDIR /root

ENV LANG=C.UTF-8

ENTRYPOINT ["/root/.nix-profile/bin/zsh"]
