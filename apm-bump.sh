#!/usr/bin/env bash

rm -r ./.agents
rm -r ./.claude
rm -r ./.codex

apm install --update -t codex,claude
apm compile -t codex
