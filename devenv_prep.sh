#!/usr/bin/env bash

set -Cue

dir=$(dirname $0)

${dir}/devenv/scripts/add_mcp_tools.sh project || true
${dir}/devenv/scripts/init_agents_md.sh
${dir}/devenv/scripts/init_subagents.sh
