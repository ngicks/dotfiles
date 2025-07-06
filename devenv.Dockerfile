# syntax=docker/dockerfile:1.4

FROM ubuntu:noble-20250619

WORKDIR /root

RUN <<EOF
  apt-get update
  apt-get install -y --no-install-recommends\
      ca-certificates \
      git \
      curl \
      make \
      build-essential \
      gcc \
      clang \
      xsel \
      p7zip-full \
      unzip \
      jq \
      tmux \
      libyaml-dev \
      zlib1g-dev
EOF

WORKDIR /root/bin

RUN <<EOF
  curl -L https://github.com/TomWright/dasel/releases/download/v2.8.1/dasel_linux_amd64.gz -o dasel.gz
  gzip -d ./dasel.gz
  chmod +x dasel
EOF

WORKDIR /root/.dotfiles
RUN <<EOF
  git clone https://github.com/ngicks/dotfiles.git .

  git submodule update --init --recursive
  cp ./ngpkgmgr/prebuilt/linux-amd64/* ~/bin

  # ruby installation stuck. Do it twice
  export PATH=$HOME/bin:$PATH
  ./install_sdk.sh
  . ~/.config/env/00_path.sh
  export PATH=$HOME/.local/rbenv/shims/ruby:$HOME/bin:$PATH
  ./install_sdk.sh

  ~/.deno/bin/deno task install

  . ~/.config/env/00_path.sh
  deno task basetool:install 
  deno task gotools:install 
EOF

WORKDIR /root/.dotfiles
RUN <<EOF
  export PATH=$HOME/bin:$PATH
  . ~/.config/env/00_path.sh
  # if an update includes deno's (almost impossible), 
  # update may fails because a deno executable got swapped
  deno task update:all || deno task update:all
EOF

WORKDIR /root
# claude code knows it.
RUN $HOME/.cargo/bin/cargo install ripgrep

WORKDIR /root/.dotfiles
RUN <<EOF
  export PATH=$HOME/bin:$PATH
  . ~/.config/env/00_path.sh
  npm install -g @anthropic-ai/claude-code
EOF

ENV CLAUDE_CONFIG_DIR=/root/.config/claude 

WORKDIR /root
