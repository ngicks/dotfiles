{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    # Core runtime tools (invoked by crun-vm Rust code)
    qemu-utils     # qemu-img
    openssh        # ssh, ssh-keygen
    cdrkit         # genisoimage

    # Libvirt stack (used by embedded scripts)
    libvirt        # virsh, libvirtd, virtqemud, virtlogd
    virtiofsd      # vhost-user virtio-fs backend

    # Container image tools
    skopeo         # OCI image operations

    # Networking
    passt          # user-mode networking (pasta/passt)

    # Standard tools (for embedded shell scripts)
    gnugrep
    gnused
    gnutar
    coreutils
    util-linux     # script(1)

    # Libraries
    libselinux
  ];

  shellHook = ''
    # NOTE: crun-vm's embedded scripts hardcode /usr/libexec/virtiofsd.
    # The nix-provided virtiofsd is on PATH instead. If crun-vm fails
    # to find virtiofsd, create a symlink:
    #   sudo ln -sf $(command -v virtiofsd) /usr/libexec/virtiofsd
  '';
}
