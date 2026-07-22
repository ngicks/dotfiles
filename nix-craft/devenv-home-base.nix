# OCI base image for the devenv container (localhost/devenv/devenv-home-base),
# assembled with nix2container so the home-manager package closure is split
# into content-addressed layers that survive rebuilds. The flake only wires
# flake inputs into this file; everything image-specific belongs here.
{
    pkgs,
    home-manager,
    nix2containerLib,
    system,
}:
let
    lib = pkgs.lib;

    # Reuse the host modules, but evaluate them for the container's root
    # user instead of inheriting USER and HOME from the build machine.
    containerHome = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
            ./home/home.nix
            {
                home.username = lib.mkForce "root";
                home.homeDirectory = lib.mkForce "/root";
                # The nixos/nix base image used to supply these core
                # tools through its default profile; nothing else
                # provides them on the nix2container rootfs, and the
                # Containerfile depends on mkdir/touch/bash at
                # /root/.nix-profile/bin.
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
                systemd.user.startServices = lib.mkForce false;
            }
        ];
    };

    # Building from scratch means the FHS skeleton a base image would
    # normally provide is our responsibility. Modes are not set here:
    # the nix store normalizes every path to 0555/0444, so writability
    # is restored via `perms` at layer-tar time instead.
    rootfs = pkgs.runCommand "devenv-home-rootfs" { } ''
        mkdir -p \
            "$out/bin" \
            "$out/dev" \
            "$out/etc" \
            "$out/home" \
            "$out/media" \
            "$out/mnt" \
            "$out/opt" \
            "$out/proc" \
            "$out/root" \
            "$out/run" \
            "$out/srv" \
            "$out/sys" \
            "$out/tmp" \
            "$out/usr/bin" \
            "$out/var/cache" \
            "$out/var/empty" \
            "$out/var/lib" \
            "$out/var/log" \
            "$out/var/spool" \
            "$out/var/tmp"

        ln -s ../run "$out/var/run"
        ln -s ../run/lock "$out/var/lock"

        ln -s ${pkgs.bashInteractive}/bin/bash "$out/bin/sh"
        ln -s ${pkgs.coreutils-full}/bin/env "$out/usr/bin/env"
        ln -s ${pkgs.cacert}/etc/ssl/certs "$out/etc/ssl-certs"
        ln -s ${pkgs.glibc}/lib "$out/lib"
        ln -s ${pkgs.glibc}/lib64 "$out/lib64"
        ln -s ${pkgs.glibc.dev}/include "$out/usr/include"
        ln -s ${pkgs.iana-etc}/etc/services "$out/etc/services"
        ln -s ${pkgs.iana-etc}/etc/protocols "$out/etc/protocols"

        ln -s ${containerHome.activationPackage}/home-path \
            "$out/root/.nix-profile"
        cp -a ${containerHome.activationPackage}/home-files/. \
            "$out/root/"

        cat > "$out/etc/passwd" <<'EOF'
        root:x:0:0:root:/root:/root/.nix-profile/bin/zsh
        EOF
        cat > "$out/etc/group" <<'EOF'
        root:x:0:
        EOF
        cat > "$out/etc/nsswitch.conf" <<'EOF'
        hosts: files dns
        passwd: files
        group: files
        EOF
    '';

    # Keep the comparatively stable package closure separate from the
    # small Home Manager file/link layer. Editing shell/editor config
    # then does not force the large package layer to be recopied.
    homePackagesLayer = nix2containerLib.buildLayer {
        deps = [ containerHome.config.home.path ];
        maxLayers = 253;
        metadata = {
            created_by = "home-manager package closure";
        };
    };
in
nix2containerLib.buildImage {
    # The load script selects the semantic destination tag with
    # copyTo. This internal tag is not written to Podman.
    name = "localhost/devenv/devenv-home-base";
    tag = "unversioned";
    copyToRoot = rootfs;
    # Matched with re.Match (unanchored) against the absolute store
    # path of each tarred file, hence the ^${rootfs} anchor.
    # /var/empty is intentionally left 0555 (sshd privsep requires it
    # non-writable).
    perms = [
        {
            path = rootfs;
            regex = "^${rootfs}/(var/)?tmp$";
            mode = "1777";
        }
        {
            path = rootfs;
            regex = "^${rootfs}/(bin|dev|etc|home|media|mnt|opt|proc|run|srv|sys|usr(/bin)?|var(/(cache|lib|log|spool))?)$";
            mode = "0755";
        }
    ];
    layers = [ homePackagesLayer ];
    maxLayers = 2;
    initializeNixDatabase = true;

    config = {
        entrypoint = [ "/root/.nix-profile/bin/zsh" ];
        workingDir = "/root";
        env = [
            "HOME=/root"
            "USER=root"
            "LANG=C.UTF-8"
            "PATH=/root/.nix-profile/bin:/bin"
            "SHELL=/root/.nix-profile/bin/zsh"
            "SSL_CERT_FILE=/etc/ssl-certs/ca-bundle.crt"
            "NIX_SSL_CERT_FILE=/etc/ssl-certs/ca-bundle.crt"
        ];
        labels = {
            "org.opencontainers.image.source" = "https://github.com/ngicks/dotfiles";
            "dev.ngicks.dotfiles.builder" = "nix2container";
            "dev.ngicks.dotfiles.role" = "home-manager-base";
            "dev.ngicks.dotfiles.system" = system;
        };
    };
}
