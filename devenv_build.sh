#!/usr/bin/env bash

set -Cue

cmdman run --name devenv-image-build -- dotfilesmgr standalone devenv build
