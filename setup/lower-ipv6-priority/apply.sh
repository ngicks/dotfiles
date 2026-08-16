#!/usr/bin/env bash

set -euo pipefail

gai_conf_path="${GAI_CONF_PATH:-/etc/gai.conf}"
rule='precedence ::ffff:0:0/96  100'

if [[ $(uname -s) != Linux ]] || ! getconf GNU_LIBC_VERSION >/dev/null 2>&1; then
  echo "error: this setup requires Linux with glibc" >&2
  exit 1
fi

if [[ $gai_conf_path == /etc/gai.conf && $(id -u) -ne 0 ]]; then
  echo "error: run with sudo" >&2
  exit 1
fi

if [[ -f $gai_conf_path ]] && grep -Eq '^[[:space:]]*precedence[[:space:]]+::ffff:0:0/96[[:space:]]+100([[:space:]]*(#.*)?)?$' "$gai_conf_path"; then
  echo "already configured: $gai_conf_path"
  exit 0
fi

if [[ ! -e $gai_conf_path ]]; then
  install -m 0644 /dev/null "$gai_conf_path"
fi

printf '\n# Prefer IPv4 when IPv6 addresses resolve but have no working route.\n%s\n' "$rule" \
  >>"$gai_conf_path"

echo "configured: $gai_conf_path"

