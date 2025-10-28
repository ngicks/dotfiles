# syntax=docker/dockerfile:1

ARG HTTP_PROXY=""
ARG HTTPS_PROXY=""
ARG http_proyx=${HTTP_PROXY}
ARG https_proyx=${HTTPS_PROXY}
ARG NO_PROXY=""
ARG no_proxy=${NO_PROXY}

FROM docker.io/library/ubuntu:noble-20250619

RUN rm -f /etc/apt/apt.conf.d/docker-clean

RUN --mount=type=secret,id=cert,target=/ca-certificates.crt \
    --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
<<EOF
  apt-get update
  apt-get install -y --no-install-recommends\
      gpg \
      gnupg2 \
      ca-certificates \
      git \
      curl \
      wget \
      vim \
      less \
      sudo
  mkdir ~/.gnupg
  chmod 700 ~/.gnupg
EOF

WORKDIR /root/.dotfiles

RUN --mount=type=secret,id=cert,target=/ca-certificates.crt \
    --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
<<EOF
  if [ -f "/ca-certificates.crt" ]; then
    export SSL_CERT_FILE="/ca-certificates.crt"
    export NODE_EXTRA_CA_CERTS="/ca-certificates.crt"
  fi
  git clone https://github.com/ngicks/dotfiles.git .
  git submodule update --init --recursive
  ./install_dependencies.sh
EOF

RUN --mount=type=secret,id=cert,target=/ca-certificates.crt \
<<EOF
  if [ -f "/ca-certificates.crt" ]; then
    export SSL_CERT_FILE="/ca-certificates.crt"
    export NODE_EXTRA_CA_CERTS="/ca-certificates.crt"
  fi
  ~/.local/bin/mise trust "$HOME/.config/mise"
  ~/.local/bin/mise trust "$HOME/.dotfiles/.config/mise/config.toml"
  mkdir /root/.config
  ~/.local/bin/mise exec deno -- deno task install
EOF

RUN <<EOF
  if [ -f ~/.zshrc ]; then
    sed -i 's/^ZSH_THEME=.*/ZSH_THEME="obraun"/' ~/.zshrc
  else
    echo 'ZSH_THEME="obraun"' >> ~/.zshrc
  fi
EOF

RUN --mount=type=secret,id=cert,target=/ca-certificates.crt \
<<EOF
  if [ -f "/ca-certificates.crt" ]; then
    export SSL_CERT_FILE="/ca-certificates.crt"
    export NODE_EXTRA_CA_CERTS="/ca-certificates.crt"
  fi
  ~/.local/bin/mise exec github:neovim/neovim@latest -- nvim --headless "+Lazy! restore" +qa || echo "somewhat failed"
EOF

RUN --mount=type=secret,id=cert,target=/ca-certificates.crt \
<<EOF
  # cache deps in case it would be manually called.
  if [ -f "/ca-certificates.crt" ]; then
    export SSL_CERT_FILE="/ca-certificates.crt"
    export NODE_EXTRA_CA_CERTS="/ca-certificates.crt"
    export DENO_CERT="/ca-certificates.crt"
  fi
  ~/.local/bin/mise trust "$HOME/.config/mise"
  ~/.local/bin/mise trust "$HOME/.dotfiles/.config/mise/config.toml"
  ~/.local/bin/mise exec deno -- deno task update:daily
  # no config auto update
  touch "${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/.no_update_daily"
EOF

WORKDIR /root

ENV SHELL="/usr/bin/zsh" 
ENTRYPOINT ["/usr/bin/zsh"]
