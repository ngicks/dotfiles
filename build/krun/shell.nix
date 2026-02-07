{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShell {
  buildInputs = with pkgs; [
    yajl
    libseccomp
    libcap
    systemd
    pkg-config
    go-md2man
    python3
    autoconf
    automake
    libtool

    libkrun
  ];
}
