#!/usr/bin/env bash

set -Cue

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cmdman run --workdir "${here}" --name devenv-image-build -- dotfilesmgr standalone devenv build
