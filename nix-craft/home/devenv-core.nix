{ pkgs, lib, config, ... }:

let
  # limactl refuses to run as root, and the from-scratch rootfs has no su/sudo
  # (no PAM, no setuid bits). Root holds CAP_SETUID/CAP_SETGID in the container,
  # so setpriv is enough to drop to the `lima` user that
  # ../devenv-home-base.nix writes into /etc/passwd.
  #
  # --keep-groups is deliberate: /dev/kvm is reachable only through the host
  # kvm gid that `--group-add keep-groups` leaves on the process as an unmapped
  # supplementary group. setgroups() cannot re-add an unmapped gid inside the
  # user namespace, so --init-groups or --groups would lose KVM. The cost is
  # that gid 0 also stays in the supplementary set.
  asLima = pkgs.writeShellScriptBin "as-lima" ''
    set -eu

    if [ "$#" -eq 0 ]; then
      echo "usage: as-lima <command> [args...]" >&2
      exit 2
    fi

    if [ "$(${pkgs.coreutils-full}/bin/id -u)" != "0" ]; then
      exec "$@"
    fi

    # Only the identity-bound variables change; PATH and the rest of the
    # session carry over so the nix profile and mise shims stay reachable.
    # XDG_*_HOME are cleared rather than rewritten so the usual $HOME-relative
    # defaults apply under /home/lima.
    exec ${pkgs.util-linux}/bin/setpriv --reuid=lima --regid=lima --keep-groups -- \
      ${pkgs.coreutils-full}/bin/env \
        -u XDG_CONFIG_HOME -u XDG_DATA_HOME -u XDG_CACHE_HOME -u XDG_STATE_HOME \
        HOME=/home/lima USER=lima LOGNAME=lima \
        LIMA_HOME=/home/lima/.local/share/lima \
        XDG_RUNTIME_DIR=/run/user/1000 \
        "$@"
  '';
in
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
      asLima
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

    # Playwright's chromium links fontconfig statically, so LD_LIBRARY_PATH
    # cannot help it: it needs a fonts.conf plus real font files, and the
    # from-scratch rootfs has no /etc/fonts. Referencing the derivation here
    # also pulls the fonts into the image closure. CJK fonts are included
    # because pages under test render CJK text.
    home.sessionVariables.FONTCONFIG_FILE = pkgs.makeFontsConf {
      fontDirectories = [
        pkgs.dejavu_fonts
        pkgs.noto-fonts-cjk-sans
      ];
    };
  };
}
