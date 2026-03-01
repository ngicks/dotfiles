#!/usr/bin/env bash

set -e

pushd ./config/mise/
  # it always fails because of read-only lock file
  mise install --locked
  mise prune -y --locked
popd

