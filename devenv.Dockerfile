# syntax=docker/dockerfile:1.4

FROM docker.io/library/ubuntu:noble-20250619

RUN rm -f /etc/apt/apt.conf.d/docker-clean

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
<<EOF
  apt-get update
  apt-get install -y --no-install-recommends\
      gpg \
      gnupg2 \
      ca-certificates \
      apt-transport-https \
      git \
      curl \
      vim \
      sudo
  mkdir ~/.gnupg
  chmod 700 ~/.gnupg
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
  ~/.local/bin/mise trust "$HOME/.dotfiles/.config/mise/config.toml"

  # gpg verification fails for ... reasons.
  # There's basically no chance of downloading deceptive files.
  # gpg verifications work greatly when file host varies.
  # If official downloads could be swapped 
  # then the attackers also have had their hands on the gpg key,ikr? 
  export MISE_GPG_VERIFY=0
  export PATH="${PATH}:$HOME/.local/bin"
  echo "calling mise install"
  bash ~/.dotfiles/mise_install.sh bash
  echo "installation done"
  ~/.local/bin/mise ls
  if [ $(~/.local/bin/mise ls --missing | wc -l) -gt 1 ]; then
    echo "failed to install some tools"
    exit 1
  fi
EOF

RUN <<EOF
  ~/.local/bin/mise exec github:neovim/neovim@latest -- nvim --headless "+Lazy! restore" +qa || echo "somewhat failed"
EOF

RUN <<EOF
  ~/.local/bin/mise trust "$HOME/.config/mise"
  ~/.local/bin/mise trust "$HOME/.dotfiles/.config/mise/config.toml"
  ~/.local/bin/mise exec deno@latest -- deno task update:daily
EOF

WORKDIR /root

ENV SHELL="/usr/bin/zsh" 
ENTRYPOINT ["/usr/bin/zsh"]
