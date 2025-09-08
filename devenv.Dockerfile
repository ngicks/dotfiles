# syntax=docker/dockerfile:1.4

FROM ubuntu:noble-20250619

RUN rm -f /etc/apt/apt.conf.d/docker-clean

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
<<EOF
  apt-get update
  apt-get install -y --no-install-recommends\
      ca-certificates \
      git \
      curl \
      sudo
EOF

WORKDIR /root/.dotfiles

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
<<EOF
  git clone https://github.com/ngicks/dotfiles.git .
  git submodule update --init --recursive
  ./install_dependencies.sh
EOF


RUN <<EOF
  ~/.local/bin/mise trust "$HOME/.config/mise"
  ~/.local/bin/mise trust "$HOME/.dotfiles/.config/mise/config.toml"
  mkdir /root/.config
  ~/.local/bin/mise exec deno@latest -- deno task install
EOF

RUN <<EOF
  if [ -f ~/.zshrc ]; then
    sed -i 's/^ZSH_THEME=.*/ZSH_THEME="obraun"/' ~/.zshrc
  else
    echo 'ZSH_THEME="obraun"' >> ~/.zshrc
  fi
EOF

RUN <<EOF
  ~/.local/bin/mise trust "$HOME/.config/mise"

  for f in $(ls $HOME/.config/initial_path); do
    . $HOME/.config/initial_path/$f
  done

  ~/.local/bin/mise install || ~/.local/bin/mise install
EOF


RUN <<EOF
  ~/.local/bin/mise trust "$HOME/.config/mise"
  ~/.local/bin/mise trust "$HOME/.dotfiles/.config/mise/config.toml"
  ~/.local/bin/mise exec deno@latest -- deno task update:daily
EOF

WORKDIR /root

ENV SHELL="/usr/bin/zsh" 
ENTRYPOINT ["/usr/bin/zsh"]
