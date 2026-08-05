# GPU-enabled rootless podman in WSL2

Wires an NVIDIA GPU into rootless podman containers inside a WSL2 distro
via CDI (Container Device Interface). CDI needs no root helper at
runtime, so plain rootless `podman run` works once the spec exists.

Only `apt`-based distros are scripted (this repo is tested against
Ubuntu); on other distros follow the NVIDIA repo setup manually and the
rest still applies.

## How it fits together

- The GPU driver lives on **Windows**. The distro must NOT have a Linux
  NVIDIA driver; WSL exposes the GPU as `/dev/dxg` and the userspace
  libraries under `/usr/lib/wsl/lib`.
- `nvidia-container-toolkit` provides `nvidia-ctk`, which generates a
  CDI spec describing those mounts. It auto-detects WSL2.
- podman (>= 4.1) reads the spec and injects the device with
  `--device nvidia.com/gpu=all`. WSL exposes GPUs as the single `all`
  device.

## On Host (Windows)

Install the normal NVIDIA driver and keep WSL current:

```ps1
wsl --update
```

## On Linux

Run from this directory, in order. Every script is idempotent.

```sh
./check-prerequisites.sh                # read-only; verifies GPU passthrough,
                                        #   podman, subuid/subgid, uidmap
sudo ./install-nvidia-container-toolkit.sh  # NVIDIA apt repo + nvidia-container-toolkit
sudo ./generate-cdi.sh                  # -> /etc/cdi/nvidia.yaml
./test-gpu-container.sh                 # rootless `podman run ... nvidia-smi -L`
```

`check-prerequisites.sh` prints a remediation hint for each failed
check; fix and rerun until it passes before moving on.

## Maintenance

The CDI spec pins library paths and driver versions. Rerun after a
Windows driver update or `wsl --update`:

```sh
sudo ./generate-cdi.sh
```

The spec is written to `/etc/cdi/` rather than `/var/run/cdi/`
deliberately: `/var/run` is tmpfs and WSL VMs shut down often, and the
`nvidia-cdi-refresh` systemd service that would repopulate it only runs
on systemd-enabled distros.

## Usage

```sh
podman run --rm --device nvidia.com/gpu=all \
  docker.io/nvidia/cuda:12.6.2-base-ubuntu24.04 nvidia-smi -L
```

Do not combine with `--gpus` or the legacy `nvidia-container-runtime`
hook; CDI replaces both. Add `--security-opt=label=disable` on SELinux
distros only.

## Troubleshooting

- `unresolvable CDI devices nvidia.com/gpu=all`: the spec is missing,
  stale, or unreadable by your user. Rerun `sudo ./generate-cdi.sh` and
  check `/etc/cdi/nvidia.yaml` is world-readable (default 0644 is fine).
- `nvidia-smi` missing in the container but the device resolves: spec is
  stale after a driver update — regenerate.
- `/dev/dxg` missing: Windows-side problem; update the Windows driver
  and `wsl --update`, then restart WSL (`wsl --shutdown`).

## Remove

```sh
sudo rm /etc/cdi/nvidia.yaml
sudo apt-get purge nvidia-container-toolkit nvidia-container-toolkit-base \
  libnvidia-container-tools libnvidia-container1
sudo rm /etc/apt/sources.list.d/nvidia-container-toolkit.list \
  /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
```
