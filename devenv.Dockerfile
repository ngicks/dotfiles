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
  chsh -s $(which zsh)
EOF

RUN <<EOF
  ~/.local/bin/mise trust "$HOME/.config/mise"

  for f in $(ls $HOME/.config/initial_path); do
    . $f
  done

  ~/.local/bin/mise install || ~/.local/bin/mise install
EOF

ENV CLAUDE_CONFIG_DIR=/root/.config/claude 

WORKDIR /root

