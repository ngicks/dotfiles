#!/usr/bin/env bash

pushd $(dirname $0)

set -Cue

podman_version=v5.8.0
repo_tag=localhost/podman-static/podman:${podman_version}


podman buildx build . \
  -f ./Containerfile.podman \
  -t  ${repo_tag}\
  --build-arg=PODMAN_VERSION=${podman_version} \
  --build-arg=HTTP_PROXY=${HTTP_PROXY:-} \
  --build-arg=HTTPS_PROXY=${HTTPS_PROXY:-${HTTP_PROXY:-}} \
  --build-arg=NO_PROXY=${NO_PROXY:-} \
  --build-arg=http_proxy=${http_proxy:-${HTTP_PROXY:-}} \
  --build-arg=https_proxy=${https_proxy:-${http_proxy:-${HTTPS_PROXY:-${HTTP_PROXY:-}}}} \
  --build-arg=no_proxy=${no_proxy:-${NO_PROXY:-}} \
  --secret id=cert,src=${SSL_CERT_FILE:-"/etc/ssl/certs/ca-certificates.crt"}


mkdir -p ./out

podman container run --mount type=bind,src=./out,dst=/out --workdir=/ localhost/podman-static/podman:v5.8.0 cp '/usr/local/bin/podman' /out/

popd

