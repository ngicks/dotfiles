#!/usr/bin/env bash

# Read-only. Verifies everything the later scripts assume; prints a
# remediation hint per failed check and exits non-zero if any failed.

failed=0

check() {
  local desc="$1" hint="$2"
  shift 2
  if "$@" &> /dev/null; then
    echo "ok:   ${desc}"
  else
    echo "FAIL: ${desc}"
    echo "      hint: ${hint}"
    failed=1
  fi
}

grep -qi microsoft /proc/version \
  || echo "WARNING: kernel does not look like WSL2; this setup is WSL2-specific"

check "GPU device node /dev/dxg" \
  "install the NVIDIA driver on Windows, run 'wsl --update', then 'wsl --shutdown'" \
  test -e /dev/dxg

check "WSL driver libraries (/usr/lib/wsl/lib/nvidia-smi)" \
  "same as above; the Windows driver provides these" \
  test -x /usr/lib/wsl/lib/nvidia-smi

check "nvidia-smi sees the GPU" \
  "update the Windows NVIDIA driver" \
  /usr/lib/wsl/lib/nvidia-smi -L

check "no Linux NVIDIA driver installed in the distro" \
  "remove it; in WSL2 the driver must come from Windows only" \
  bash -c '! command -v dpkg > /dev/null || ! dpkg -l "nvidia-driver-*" 2> /dev/null | grep -q "^ii"'

check "podman >= 4.1" \
  "install podman 4.1+ (CDI support)" \
  bash -c 'ver=$(podman --version | grep -oE "[0-9]+\.[0-9]+" | head -1)
           [ "$(printf "%s\n4.1\n" "$ver" | sort -V | head -1)" = "4.1" ]'

check "newuidmap/newgidmap present" \
  "sudo apt-get install -y uidmap" \
  bash -c 'command -v newuidmap && command -v newgidmap'

check "subuid/subgid entries for ${USER}" \
  "sudo usermod --add-subuids 100000-165535 --add-subgids 100000-165535 ${USER}; then 'podman system migrate'" \
  bash -c "grep -q \"^${USER}:\" /etc/subuid && grep -q \"^${USER}:\" /etc/subgid"

if [ "$failed" -ne 0 ]; then
  echo
  echo "some checks failed; fix and rerun"
  exit 1
fi
echo
echo "all checks passed"
