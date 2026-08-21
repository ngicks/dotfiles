{ pkgs, lib, config, ... }:

{
  # Core tools the nix2container devenv rootfs cannot get from a base image;
  # the host user gets them from the distro, so they are added only when the
  # config is evaluated for the container's root user. Keeping this in the
  # shared module tree (not just devenv-home-base.nix) lets an in-container
  # `home-manager switch` rebuild the profile without stripping them.
  config = lib.mkIf (config.home.username == "root") {
    home.packages = with pkgs; [
      nix
      bashInteractive
      coreutils-full
      findutils
      diffutils
      gnutar
      gzip
      which
      less
      openssh
    ];

    # Runtime libraries for playwright-downloaded chromium (store configured in
    # config/loginscript/env/00_playwright.sh): the from-scratch rootfs has no
    # FHS lib dirs, so the browser's NEEDED libs must come via LD_LIBRARY_PATH.
    # Chromium only — firefox/webkit need much larger closures. mkForce because
    # home.sessionVariables entries do not merge; this supersedes the host
    # definition in home.nix, whose stdenv.cc.cc.lib entry is repeated here.
    # Shadowing nix binaries' RUNPATH is acceptable: these libs come from the
    # same nixpkgs eval as everything else in the image.
    home.sessionVariables.LD_LIBRARY_PATH = lib.mkForce (pkgs.lib.makeLibraryPath (with pkgs; [
      stdenv.cc.cc.lib
      alsa-lib
      at-spi2-core # also provides libatk and libatk-bridge (merged upstream)
      cairo
      cups
      dbus
      expat
      glib
      libx11
      libxcb
      libxcomposite
      libxdamage
      libxext
      libxfixes
      libxkbcommon
      libxrandr
      libgbm
      nspr
      nss
      pango
      systemdLibs # libudev
    ]));
  };
}
