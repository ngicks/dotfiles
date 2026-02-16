#!/usr/bin/env bash

pushd $(dirname $0)

set -Cue

crun_version=$(cat $(dirname $0)/tag)

repo_tag=localhost/krun/crun:${crun_version}

if ! podman image exists $repo_tag >/dev/null 2>&1
  podman buildx build . \
    -f ./Containerfile.krun \
    -t ${repo_tag} \
    --build-arg=CRUN_VERSION=${crun_version} \
    --build-arg=HTTP_PROXY=${HTTP_PROXY:-} \
    --build-arg=HTTPS_PROXY=${HTTPS_PROXY:-${HTTP_PROXY:-}} \
    --build-arg=NO_PROXY=${NO_PROXY:-} \
    --build-arg=http_proxy=${http_proxy:-${HTTP_PROXY:-}} \
    --build-arg=https_proxy=${https_proxy:-${http_proxy:-${HTTPS_PROXY:-${HTTP_PROXY:-}}}} \
    --build-arg=no_proxy=${no_proxy:-${NO_PROXY:-}} \
    --secret id=cert,src=${SSL_CERT_FILE:-"/etc/ssl/certs/ca-certificates.crt"}
fi

mkdir -p ./out/${crun_version}

container_id=""
cleanup() {
  if [ -n "$container_id" ]; then 
    return 0
  fi
  podman container rm -f $container_id
}
trap "cleanup" EXIT INT TERM HUP

container_id=$(podman container create $repo_tag)
podman export "$container_id" | tar -x -C ./out/${crun_version} 
podman container rm $container_id
container_id=""

popd
