# syntax=docker/dockerfile:1.4

FROM ubuntu:noble-20250619

WORKDIR /root
RUN apt-get update && apt-get install -y\
    ca-certificates \
    git \
    curl \
    make \
    build-essential \
    gcc \
    clang \
    xsel \
    p7zip-full \
    jq \
    tmux \
    libyaml-dev \
    zlib1g-dev

WORKDIR /root/bin
RUN curl -L https://github.com/TomWright/dasel/releases/download/v2.8.1/dasel_linux_amd64.gz -o dasel.gz &&\
    gzip -d ./dasel.gz &&\
    chmod +x dasel

WORKDIR /root
RUN git clone https://github.com/ngicks/dotfiles.git /root/.dotfiles

WORKDIR /root/.dotfiles
RUN git submodule update --init --recursive
# ruby installation stuck. Do it twice
RUN cp ./ngpkgmgr/prebuilt/linux-amd64/* ~/bin
RUN PATH=$HOME/bin:$PATH ./install_sdk.sh
RUN . ~/.config/env/00_path.sh  && PATH=$HOME/.local/rbenv/shims/ruby:$HOME/bin:$PATH ./install_sdk.sh

RUN ~/.deno/bin/deno task install

RUN . ~/.config/env/00_path.sh  && PATH=$HOME/.local/rbenv/shims/ruby:$HOME/bin:$PATH deno task basetool:install && deno task gotools:install 
RUN . ~/.config/env/00_path.sh  && PATH=$HOME/.local/rbenv/shims/ruby:$HOME/bin:$PATH ./update_twice.sh

# claude code knows it.
RUN $HOME/.cargo/bin/cargo install ripgrep

RUN . ~/.config/env/00_path.sh  && PATH=$HOME/.local/rbenv/shims/ruby:$HOME/bin:$PATH npm install -g @anthropic-ai/claude-code

ENV CLAUDE_CONFIG_DIR=/root/.config/claude 

WORKDIR /root
