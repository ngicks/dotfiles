{ pkgs, ... }:

{
  # moonbitlang/async loads OpenSSL with dlopen(3), so libssl is not recorded
  # as an ELF dependency of native MoonBit executables. Give the systemd unit
  # a stable path to the Nix library output without hard-coding its store hash.
  home.file.".local/lib/dotfilesmgr-openssl".source = "${pkgs.openssl.out}/lib";

  # Binries built by moonbit opens libssl using dlopen(3)
  # But it is built in nix env, but dlopen tries to open host OS world.
  home.file.".local/bin/override/dotfilesmgr" = {
    executable = true;
    text = ''
      #!/bin/sh
      export LD_LIBRARY_PATH="$HOME/.local/lib/dotfilesmgr-openssl''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
      exec "$HOME/.local/share/mise/shims/dotfilesmgr" "$@"
    '';
  };

  # The dotfiles server loads ~/.config/dotfilesmgr/.env on startup; manage
  # it declaratively here. See config/dotfilesmgr/.env.example for the full
  # set of supported keys.
  xdg.configFile."dotfilesmgr/.env".text = ''
    # Enable automatic devenv image rebuilds when the upstream checkout advances.
    DOTFILES_SERVER_AUTO_BUILD=1
  '';
}
