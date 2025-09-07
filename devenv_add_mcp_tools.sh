#!/bin/bash

claude mcp add serena --scope user -- uvx --from git+https://github.com/oraios/serena serena start-mcp-server --context ide-assistant --project .
claude mcp add context7 --scope user -- npx -y @upstash/context7-mcp
