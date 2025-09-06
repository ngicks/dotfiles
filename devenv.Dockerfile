# syntax=docker/dockerfile:1.4

FROM ubuntu:noble-20250619

RUN <<EOF
  apt-get update
  apt-get install -y --no-install-recommends\
      ca-certificates \
      git \
      curl \
      sudo
EOF

WORKDIR /root/.dotfiles

RUN <<EOF
  git clone https://github.com/ngicks/dotfiles.git .
  git submodule update --init --recursive
  ./install_dependencies.sh
EOF

RUN <<EOF
  ~/.local/bin/mise trust "~/.config/mise"
  ~/.local/bin/mise exec deno@latest -- deno task install
EOF

RUN <<EOF
  . ~/.bashrc
  eval "$($HOME/.local/bin/mise activate bash)"
  mise install
EOF

ENV CLAUDE_CONFIG_DIR=/root/.config/claude 

WORKDIR /root

