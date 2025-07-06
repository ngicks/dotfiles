# syntax=docker/dockerfile:1.4

FROM ubuntu:noble-20250619

RUN <<EOF
apt-get update
apt-get install -y --no-install-recommends\
    ca-certificates \
    git \
    curl \
    unzip \
    jq
curl -o- https://fnm.vercel.app/install | bash
/root/.local/share/fnm/fnm install 24
eval "`/root/.local/share/fnm/fnm env`"
npm install -g @anthropic-ai/claude-code
EOF

ENV CLAUDE_CONFIG_DIR=/root/.config/claude

WORKDIR /root
