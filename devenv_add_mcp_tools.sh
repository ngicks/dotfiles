#!/bin/bash

claude mcp add serena --scope project -- uvx --from git+https://github.com/oraios/serena serena start-mcp-server --context ide-assistant --project $(pwd)
