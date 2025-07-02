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
RUN ./install_sdk.sh
RUN ~/.deno/bin/deno task install
RUN . ~/.bashrc && ./update_twice.sh
# claude code knows it.
RUN cargo install ripgrep
