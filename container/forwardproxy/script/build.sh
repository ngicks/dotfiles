#!/usr/bin/env bash
# Build the forwardproxy image with a FIXED tag read from ./tag.
#
# Build context is container/forwardproxy (the Containerfile COPYs from resource/
# and installs squid + heimdal from Alpine packages). No proxy build-args here:
# podman/buildah forwards the host's proxy env into build RUN steps by default and
# does not bake it into the image, so passing it explicitly is unnecessary.
#
# Keep ./tag in sync with Image= in config/containers/systemd/forwardproxy.container.
set -eCu

script_dir=$(cd "$(dirname "$0")" && pwd -P)
context_dir=$(cd "${script_dir}/.." && pwd -P)

tag_file="${context_dir}/tag"
[ -s "${tag_file}" ] || { echo "missing tag file: ${tag_file}" >&2; exit 1; }
tag=$(cat "${tag_file}")
image="localhost/devenv/forwardproxy:${tag}"

if podman image exists "${image}"; then
  echo "forwardproxy image already exists: ${image}" >&2
  exit 0
fi

exec podman build -t "${image}" -f "${context_dir}/Containerfile" "${context_dir}"
