#!/usr/bin/env bash

set -eCu

if [ -n "${TZ:-}" ]; then
  printf "%s\n" "--env TZ=${TZ}"
fi

if [ -f /etc/localtime ]; then
  printf "%s\n" "--mount type=bind,src=/etc/localtime,dst=/etc/localtime,ro"
fi
