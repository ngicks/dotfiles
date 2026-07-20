## user-mode libvirt (libvirt-sandbox)

Runs a libvirt *session* daemon (`qemu:///session`) under a dedicated
unprivileged user `libvirt-sandbox` instead of the system `libvirtd`. VMs,
qemu processes and disk images all belong to that user; other users reach the
daemon through a group-shared unix socket. The devenv container forwards that
socket (`DEVENV_LIBVIRT_SESSION=1`) so an LLM can manage VMs without ever
touching `qemu:///system`.

What the setup consists of:

- system user/group `libvirt-sandbox` (nologin, home `/var/lib/libvirt-sandbox`),
  added to group `kvm` for `/dev/kvm`
- the invoking user is added to group `libvirt-sandbox`
- lingering is enabled (`loginctl enable-linger`) so the user's systemd
  instance — and with it the daemon — starts at system boot
- monolithic `libvirtd` as a systemd *user* service, publishing its sockets at
  `/run/libvirt-sandbox` (tmpfiles-created, `2770`) instead of the default
  `/run/user/<uid>/libvirt`, which is unreachable for other users
  (`/run/user/<uid>` is `0700`)
- shared image dir `/var/lib/libvirt-sandbox/images` (setgid, `2770`)

The monolithic daemon (not modular `virtqemud` & co.) is used deliberately:
every driver (qemu, storage, network, secret) is served over the single
forwarded socket. With modular daemons each driver has its own socket and
clients resolve the secondary ones at their default session paths, which does
not survive cross-user/cross-container forwarding.

### Prerequisites

Ubuntu:

```sh
sudo apt install libvirt-daemon libvirt-clients qemu-system-x86 qemu-utils
```

`libvirt-daemon-system` is not required — the system `libvirtd` stays out of
the picture. The user unit hardcodes `/usr/sbin/libvirtd`; adjust
`files/systemd/user/libvirtd.service` on distros that install it elsewhere.

### Install

```sh
sudo ./install.sh
```

Idempotent; rerun freely (e.g. after pulling changes to `files/`). Afterwards
**re-login** (or `newgrp libvirt-sandbox`) so your new group membership takes
effect.

If a different user than the sudo invoker should join the group:
`sudo TARGET_USER=<user> ./install.sh`.

### Verify

```sh
./sandbox-systemctl.sh status libvirtd.service  # sudo-wraps itself
ls -l /run/libvirt-sandbox/                     # libvirt-sock, srwxrwx---
./virsh-sandbox.sh list --all                   # needs re-login after install
```

Logs of the sandbox session: `sudo journalctl _UID=$(id -u libvirt-sandbox)`.

Optionally point the `default` storage pool at the shared image dir:

```sh
./virsh-sandbox.sh pool-define-as default dir --target /var/lib/libvirt-sandbox/images
./virsh-sandbox.sh pool-start default
./virsh-sandbox.sh pool-autostart default
```

### Use from devenv

```sh
DEVENV_LIBVIRT_SESSION=1 DEVENV_KVM=1 ./devenv_run.sh
```

`devenv/scripts/opts.d/08-libvirt-session.sh` bind-mounts
`/run/libvirt-sandbox` and the images dir into the container (same paths, so
pool/volume paths stay valid on both sides) and presets `LIBVIRT_DEFAULT_URI`,
so a plain `virsh` inside the container talks to the sandbox daemon. Socket
access works because `--group-add keep-groups` carries your
`libvirt-sandbox` supplementary group into the rootless container.

### Notes / limitations

- Anyone in group `libvirt-sandbox` has full control over the daemon and its
  VMs — that is the point, but scope the group accordingly.
- Session-mode networking has no NAT bridge by default; guests get SLIRP
  (`user`) networking, or install `passt` for a better usermode backend.
  Bridged networking would need the setuid `qemu-bridge-helper`.
- Files you drop into `/var/lib/libvirt-sandbox/images` inherit the group via
  setgid but keep your umask; `chmod g+rw` them if qemu needs write access
  (base/backing images only need `g+r`).

### Teardown

```sh
./sandbox-systemctl.sh disable --now libvirtd.service
sudo loginctl disable-linger libvirt-sandbox
sudo rm /etc/tmpfiles.d/libvirt-sandbox.conf
sudo rm -rf /run/libvirt-sandbox
sudo gpasswd -d "$USER" libvirt-sandbox

# DESTRUCTIVE: also deletes the home dir, i.e. all VM definitions and images
sudo userdel -r libvirt-sandbox
```
