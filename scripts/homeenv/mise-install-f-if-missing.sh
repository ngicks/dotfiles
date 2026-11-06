#!/usr/bin/env bash

set -euo pipefail

go_version=$(go env GOVERSION 2>/dev/null || true)
rustc_commit=$(rustc -vV 2>/dev/null | sed -n 's/^commit-hash: //p' || true)

# Stdin redirected from /dev/null so server-style binaries (e.g. an LSP)
# exit on EOF instead of stalling.
check_bin_runs() {
  local bin="$1"
  "$bin" --version </dev/null >/dev/null 2>&1 && return 0
  "$bin" --help    </dev/null >/dev/null 2>&1 && return 0
  "$bin" version   </dev/null >/dev/null 2>&1 && return 0
  "$bin" help      </dev/null >/dev/null 2>&1 && return 0
  return 1
}

# Reinstall go/cargo tools built by an older toolchain so they pick up its
# fixes. Reading the build info needs no run of the binary.
check_bin_go_version() {
  [ "$(go version "$1" 2>/dev/null | awk '{print $NF}')" = "$go_version" ]
}

# rustc embeds no version metadata, but panic locations keep
# /rustc/<commit-hash>/ source paths of the std it linked.
check_bin_rustc_version() {
  grep -aqF "/rustc/${rustc_commit}/" "$1"
}

check_dir() {
  local bin_dir="$1" check_bin="$2"
  [ -d "$bin_dir" ] || return 1

  (
    shopt -s nullglob
    saw_bin=0
    for bin in "$bin_dir"/*; do
      [ -f "$bin" ] && [ -x "$bin" ] || continue
      saw_bin=1
      "$check_bin" "$bin" || exit 1
    done
    [ "$saw_bin" -eq 1 ]
  )
}

# Ask mise for each tool's effective bin dirs rather than assuming
# <install_path>/bin: backends differ (npm's embedded-aube installs since
# ~2026.7.14 keep bins in node_modules/.bin with no top-level bin/), and
# `mise bin-paths` runs the backend's own layout resolution.
check_tool() {
  local tool="$1" bin_dir check_bin
  while IFS= read -r bin_dir; do
    [ -n "$bin_dir" ] || continue
    check_bin=check_bin_runs
    case "$tool" in
      go:*)
        if [ -n "$go_version" ]; then
          check_bin=check_bin_go_version
        fi
        ;;
      cargo:*)
        # cargo-binstall fetches upstream's prebuilt binary, whose rustc never
        # matches the local one; comparing would reinstall it on every run.
        if [ -n "$rustc_commit" ] && [ ! -d "$bin_dir/../binstall" ]; then
          check_bin=check_bin_rustc_version
        fi
        ;;
    esac
    check_dir "$bin_dir" "$check_bin" && return 0
  done < <(mise bin-paths "$tool" 2>/dev/null)
  return 1
}

while IFS= read -r tool; do
  [ -n "$tool" ] || continue
  if check_tool "$tool"; then
    echo "ok: $tool"
  else
    echo "reinstalling: $tool"
    mise install --locked -f "$tool" || true
  fi
done < <(
  mise ls -J | jq -r '
    to_entries[]
    | select(.key | startswith("npm:")
                 or startswith("go:")
                 or startswith("cargo:")
                 or startswith("pypi:"))
    | .key as $tool
    | .value[]
    | select(.active == true)
    | $tool
  '
)
