# syntax=docker/dockerfile:1

FROM docker.io/nixos/nix:2.33.1
# FROM docker.io/library/ubuntu:noble-20260113
# FROM ghcr.io/cameronraysmith/nixpod:0.4.12

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
    git clone --depth 1 https://github.com/ngicks/dotfiles.git .
EOF

RUN --mount=type=secret,id=cert,target=/ca-certificates.crt \
<<EOF
    # For sshfs.nvim
    mkdir -p ~/mnt/sshfs
    for p in $(nix-env -q); do
        nix-env --set-flag priority 0 $p
    done
    bash ./scripts/homeenv/nix-run-home-manager.sh
EOF

ENV SHELL="/root/.nix-profile/bin/zsh"

RUN \
<<EOF
    mkdir -p "${XDG_CACHE_HOME:-/root/.cache}/dotfiles" && \
    touch "${XDG_CACHE_HOME:-/root/.cache}/dotfiles/.no_update_daily"
EOF

WORKDIR /root

ENV LANG=C.UTF-8

ENTRYPOINT ["/root/.nix-profile/bin/zsh"]
