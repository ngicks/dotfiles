#!/bin/env bash

set -e

pushd ./config/mise/
  mise up
  mise lock
popd
