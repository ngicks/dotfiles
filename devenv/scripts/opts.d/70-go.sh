#!/usr/bin/env bash

set -eCu

printf "%s\n" "--env GOBIN=${GOBIN}"
printf "%s\n" "--env GOPATH=${GOPATH}"
printf "%s\n" "--mount type=bind,src=${GOPATH},dst=${GOPATH}"
