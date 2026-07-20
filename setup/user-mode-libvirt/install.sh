#!/usr/bin/env bash

set -eCu

# Sets up a dedicated unprivileged user "libvirt-sandbox" running a libvirt
# session daemon (qemu:///session) whose sockets are shared with members of
# the libvirt-sandbox group. Idempotent; rerun freely. See README.md.

if [[ $(id -u) -ne 0 ]]; then
  echo "run as root: sudo $0" >&2
  exit 1
fi

script_dir=$(cd "$(dirname "$0")" && pwd -P)

sandbox_user=libvirt-sandbox
sandbox_home=/var/lib/${sandbox_user}
# user added to the sandbox group; the sudo invoker by default
target_user=${TARGET_USER:-${SUDO_USER:-}}

# 1. user + group (system account; the session is driven via systemd user
#    units so no login shell is needed)
if ! getent passwd "${sandbox_user}" >/dev/null; then
  useradd --system --user-group \
    --create-home --home-dir "${sandbox_home}" \
    --shell /usr/sbin/nologin \
    "${sandbox_user}"
fi
# group members must be able to traverse into the shared images dir
chmod 0750 "${sandbox_home}"

# qemu run by the sandbox user needs /dev/kvm (root:kvm 0660 on Ubuntu)
if getent group kvm >/dev/null; then
  usermod -aG kvm "${sandbox_user}"
fi

# 2. invoking user joins the sandbox group
if [[ -n "${target_user}" ]]; then
  usermod -aG "${sandbox_user}" "${target_user}"
else
  echo "[WARNING]: could not determine the invoking user (SUDO_USER unset); add yourself manually: usermod -aG ${sandbox_user} <user>" >&2
fi

# 3. shared dirs: socket dir (tmpfiles, recreated each boot) + images dir
install -m 0644 "${script_dir}/files/tmpfiles.d/libvirt-sandbox.conf" \
  /etc/tmpfiles.d/libvirt-sandbox.conf
systemd-tmpfiles --create /etc/tmpfiles.d/libvirt-sandbox.conf
install -d -m 2770 -o "${sandbox_user}" -g "${sandbox_user}" "${sandbox_home}/images"

# 4. daemon config + user unit into the sandbox user's home
install -d -m 0755 -o "${sandbox_user}" -g "${sandbox_user}" \
  "${sandbox_home}/.config" \
  "${sandbox_home}/.config/libvirt" \
  "${sandbox_home}/.config/systemd" \
  "${sandbox_home}/.config/systemd/user"
install -m 0644 -o "${sandbox_user}" -g "${sandbox_user}" \
  "${script_dir}/files/config/libvirt/libvirtd.conf" \
  "${sandbox_home}/.config/libvirt/libvirtd.conf"
install -m 0644 -o "${sandbox_user}" -g "${sandbox_user}" \
  "${script_dir}/files/systemd/user/libvirtd.service" \
  "${sandbox_home}/.config/systemd/user/libvirtd.service"

# 5. linger: start the user's systemd instance now and on every boot
loginctl enable-linger "${sandbox_user}"

# 6. enable + start the daemon inside that instance
uid=$(id -u "${sandbox_user}")
for _ in $(seq 1 50); do
  [[ -S "/run/user/${uid}/systemd/private" ]] && break
  sleep 0.2
done
if [[ ! -S "/run/user/${uid}/systemd/private" ]]; then
  echo "[ERROR]: user manager for ${sandbox_user} (user@${uid}.service) did not come up" >&2
  exit 1
fi

sandbox_systemctl() {
  runuser -u "${sandbox_user}" -- \
    env "XDG_RUNTIME_DIR=/run/user/${uid}" systemctl --user "$@"
}

sandbox_systemctl daemon-reload
if [[ -x /usr/sbin/libvirtd ]]; then
  sandbox_systemctl enable --now libvirtd.service
else
  sandbox_systemctl enable libvirtd.service
  echo "[WARNING]: /usr/sbin/libvirtd not found (apt install libvirt-daemon); service enabled but not started" >&2
fi

if [[ -S /run/libvirt-sandbox/libvirt-sock ]]; then
  echo "OK: /run/libvirt-sandbox/libvirt-sock is up"
else
  echo "[WARNING]: /run/libvirt-sandbox/libvirt-sock did not appear; inspect with: ./sandbox-systemctl.sh status libvirtd.service" >&2
fi

if [[ -n "${target_user}" ]]; then
  echo "NOTE: re-login (or \`newgrp ${sandbox_user}\`) so ${target_user}'s new group membership takes effect"
fi
