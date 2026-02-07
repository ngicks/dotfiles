#!/usr/bin/env bash

scope=${1:-"user"}

claude mcp add --scope ${scope} serena -- serena start-mcp-server --context ide-assistant --project .
claude mcp add --scope ${scope} context7 -- context7-mcp
claude mcp add --scope ${scope} codex -- codex mcp-server
