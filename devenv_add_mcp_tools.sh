#!/usr/bin/env bash

claude mcp add --scope user serena -- serena start-mcp-server --context ide-assistant --project .
claude mcp add --scope user context7 -- context7-mcp
claude mcp add --scope user codex -- codex mcp-server
