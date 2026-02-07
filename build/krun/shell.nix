{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    # Common build tools
    git
    pkg-config
    gnumake

    # crun (C/autotools) build deps
    autoconf
    automake
    libtool
    python3
    go-md2man
    yajl
    libseccomp
    libcap
    systemd
    libkrun

    # crun-vm (Rust/cargo) build deps
    # comment-in this line if your home env does not have
    # cargo enabled.
    # duplicate/nested rustup installation confuses ${RUSTUP_HOME} dir
    # rustup
    ronn
    gzip
    libselinux
  ];

  shellHook = ''
    # Ensure pkg-config can find libselinux
    export PKG_CONFIG_PATH="${pkgs.libselinux}/lib/pkgconfig:$PKG_CONFIG_PATH"
  '';
}
