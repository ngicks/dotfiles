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
  };
}
