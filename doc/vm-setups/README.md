## vm-setups

## Required packages

What we need, regardless of distro:

- qemu with KVM support and `qemu-img`
- libvirt daemon + `virsh`
- `virt-install` (CLI installer)
- `virt-manager` (GUI, optional but handy for VNC/SPICE consoles)
- `passt` (user-mode networking backend; enables `<portForward>` for
  reaching guest services from localhost)
- optional extras: OVMF (UEFI firmware), `swtpm` (TPM), `virt-viewer`
  (standalone VNC/SPICE client)

Nix (this repo, `nix-craft/home/home.nix`):

```nix
libvirt        # virsh, libvirtd
qemu_kvm       # qemu-system-* with KVM support
virt-manager   # GUI + virt-install/virt-clone/virt-xml
passt          # user-mode networking backend with <portForward> support
```

Ubuntu:

```sh
sudo apt install qemu-system-x86 qemu-utils \
  libvirt-daemon-system libvirt-clients \
  virtinst virt-manager passt
# optional: ovmf swtpm virt-viewer
sudo usermod -aG libvirt "$USER"   # for qemu:///system without sudo
```

Note: on Ubuntu/Debian `virt-install` lives in the `virtinst` package.

Rocky Linux:

```sh
sudo dnf install qemu-kvm qemu-img \
  libvirt virt-install virt-manager passt
# optional: edk2-ovmf swtpm virt-viewer
sudo systemctl enable --now libvirtd
sudo usermod -aG libvirt "$USER"
```

## Download location list

TrueNAS:

https://download.sys.truenas.net/TrueNAS-SCALE-Goldeye/25.10.4/TrueNAS-SCALE-25.10.4.iso

## Creating a golden image with virt-install (TrueNAS interactive installer)

The TrueNAS installer requires a VGA display — it does not work over a
serial console — so run the install once through VNC, then keep the
resulting disk as a read-only golden image and give each VM a qcow2
overlay on top of it.

Prerequisites: `virtlogd` and `libvirtd` running, `virt-install`,
`qemu-img`, and a VNC client reachable from wherever you are (if the
daemons run inside a container, publish the VNC port or listen on
`0.0.0.0`).

### 1. Create the target disk

TrueNAS needs a boot device of at least 16 GiB:

```sh
qemu-img create -f qcow2 /var/lib/libvirt/images/truenas-golden.qcow2 32G
```

### 2. Boot the installer

```sh
sudo virt-install \
  --name truenas-install \
  --transient \
  --memory 8192 \
  --vcpus 4 \
  --cpu host-passthrough \
  --machine pc \
  --osinfo detect=on,require=off \
  --disk path=/var/lib/libvirt/images/TrueNAS-SCALE-25.10.4-golden.qcow2,format=qcow2,bus=virtio \
  --cdrom /var/lib/libvirt/isos/TrueNAS-SCALE-25.10.4.iso \
  --network user,model=virtio \
  --graphics vnc,listen=0.0.0.0,port=5901 \
  --noautoconsole \
  --noreboot
```

- `--machine pc`: use i440fx, not q35 — see the virtio gotcha below.
  Install and run on the same machine type so the initramfs the
  installer builds matches the hardware the VM will boot on.
- `--transient`: the domain unregisters itself on shutdown; only the
  disk survives, which is all we want.
- `--noreboot`: when the installer reboots at the end, the domain powers
  off instead of booting into the installed system, keeping the image
  pristine.
- `--noautoconsole`: there is no serial console to attach to; connect
  with VNC instead.

  ```
  sudo virt-viewer truenas-install
  ```

### 3. Run the interactive installer over VNC

Connect a VNC client to `<host>:5901`, then in the installer:

1. Choose **Install/Upgrade**.
2. Select the virtio disk (`vda`) as the boot device.
3. Set the administrative user password when prompted.
4. When the install finishes, choose reboot/shutdown from the menu —
   with `--noreboot` the domain simply powers off.

### 4. Freeze the result as the golden image

```sh
mv /var/lib/libvirt/images/truenas-golden.qcow2 /abs/path/truenas-golden.qcow2
chmod 0444 /abs/path/truenas-golden.qcow2
```

Never boot the golden image read-write again. Create a per-VM overlay
backed by it and boot that instead:

```sh
qemu-img create -f qcow2 -b /abs/path/truenas-golden.qcow2 -F qcow2 \
  /var/lib/libvirt/images/<name>.qcow2
```

First-boot configuration (network, users, pools) belongs in the overlay,
not the golden image.

## Running VMs from the golden image

### Gotcha: use machine type `pc` (i440fx), not `q35`

On `q35`, libvirt places every virtio device behind a PCIe root port,
which makes qemu expose them as modern-only virtio. With the TrueNAS
kernel this fails: the modern probe dies with

```
virtio-pci 0000:04:00.0: Unable to change power state from D3cold to D0, device inaccessible
virtio-pci 0000:04:00.0: virtio_pci: leaving for legacy driver
```

and the kernel ships no legacy virtio-pci fallback, so the guest ends
up with **zero disks** and drops to an initramfs shell:

```
cannot import 'boot-pool': no such pool available
```

There is no console output on serial (TrueNAS boots on the VGA
console), so from the outside this just looks like a hang: `virsh
dominfo` shows CPU time frozen, reads but no writes on `vda`. Debug
blind guests with `virsh screenshot <name> shot.ppm` (needs a
`<video>` device).

With `machine='pc'` (i440fx) virtio devices sit on a plain PCI bus as
transitional devices and everything probes cleanly. The same applies
to the guest-agent channel below — it is a virtio-serial device and
dies the same way on q35.

### qemu-guest-agent channel

TrueNAS ships qemu-guest-agent and starts it automatically when the
channel device exists. Add to the domain XML `<devices>`:

```xml
<channel type='unix'>
  <target type='virtio' name='org.qemu.guest_agent.0'/>
</channel>
```

Verify after boot (the agent comes up ~2 min after domain start):

```sh
virsh qemu-agent-command <name> '{"execute":"guest-ping"}'   # {"return":{}}
virsh guestinfo <name> --os --hostname
```

### Interface: reaching the web GUI from localhost

User-mode networking is outbound-only by default — the guest's web UI
(port 80/443) is unreachable until a port forward is added. With the
passt backend (libvirt >= 9.2 + `passt` installed), replace the
`<interface>` element with:

```xml
<interface type='user'>
  <backend type='passt'/>
  <model type='virtio'/>
  <portForward proto='tcp' address='127.0.0.1'>
    <range start='8080' to='80'/>
  </portForward>
  <portForward proto='tcp' address='127.0.0.1'>
    <range start='8443' to='443'/>
  </portForward>
</interface>
```

After boot, `http://127.0.0.1:8080` reaches the TrueNAS UI (on WSL2 a
Windows browser reaches the same address via localhost forwarding).
The web server comes up a bit later than qemu-ga — if `guest-ping`
answers but the UI doesn't, wait a moment.

NIC changes do not apply to a running domain: `virsh destroy` and
re-`create` it.

Fallback without passt — SLIRP hostfwd via raw qemu args (requires the
`xmlns:qemu` attribute on `<domain>`; drop the `<interface>` element):

```xml
<domain type='kvm' xmlns:qemu='http://libvirt.org/schemas/domain/qemu/1.0'>
  ...
  <qemu:commandline>
    <qemu:arg value='-netdev'/>
    <qemu:arg value='user,id=fwd0,hostfwd=tcp:127.0.0.1:8080-:80,hostfwd=tcp:127.0.0.1:8443-:443'/>
    <qemu:arg value='-device'/>
    <qemu:arg value='virtio-net,netdev=fwd0'/>
  </qemu:commandline>
</domain>
```

Guests reach services listening on the hosting side's loopback via the
gateway address `10.0.2.2` (SLIRP) / the passt gateway.

### Reference domain XML

Verified working (TrueNAS SCALE 25.10.4, qemu-ga responding):

```xml
<domain type='kvm'>
  <name>truenas-vm</name>
  <memory unit='MiB'>8192</memory>
  <vcpu>4</vcpu>
  <os><type arch='x86_64' machine='pc'>hvm</type></os>
  <cpu mode='host-passthrough'/>
  <devices>
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2'/>
      <source file='/var/lib/libvirt/images/truenas-vm.qcow2'/>
      <target dev='vda' bus='virtio'/>
    </disk>
    <interface type='user'><model type='virtio'/></interface>
    <serial type='pty'/><console type='pty'/>
    <channel type='unix'>
      <target type='virtio' name='org.qemu.guest_agent.0'/>
    </channel>
    <graphics type='vnc' port='5901' listen='127.0.0.1'/>
    <video><model type='virtio'/></video>
  </devices>
</domain>
```

`virsh create truenas-vm.xml` runs it as a transient domain; use
`virsh define` + `virsh start` instead if it should survive shutdown.
In a container without a distro-standard qemu path, also add
`<emulator>/abs/path/qemu-system-x86_64</emulator>` under
`<devices>`.

## Misc

### generate serial

```
head -c 16 /dev/urandom | xxd -p | tr -d '\n'
```

### generate uuid

```
cat /proc/sys/kernel/random/uuid
```
