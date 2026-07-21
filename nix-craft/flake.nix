{
    description = "dotfiles (home-manager, Linux/macOS)";

    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
        home-manager = {
            url = "github:nix-community/home-manager";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        nix2container = {
            url = "github:nlewo/nix2container";
            inputs.nixpkgs.follows = "nixpkgs";
        };
    };

    outputs = { self, nixpkgs, home-manager, nix2container, ... }:
    let
        supportedSystems = [
            "x86_64-linux"
            "aarch64-linux"
            "x86_64-darwin"
            "aarch64-darwin"
        ];

        forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

        pkgsFor = system: import nixpkgs {
            inherit system;
            config.allowUnfreePredicate = pkg:
                builtins.elem (nixpkgs.lib.getName pkg) [
                    "zsh-abbr"
                ];
        };

        mkDevenvHomeBase = system:
        let
            pkgs = pkgsFor system;
            lib = pkgs.lib;
            nix2containerLib = nix2container.packages.${system}.nix2container;

            # Reuse the host modules, but evaluate them for the container's root
            # user instead of inheriting USER and HOME from the build machine.
            containerHome = home-manager.lib.homeManagerConfiguration {
                inherit pkgs;
                modules = [
                    ./home/home.nix
                    {
                        home.username = lib.mkForce "root";
                        home.homeDirectory = lib.mkForce "/root";
                        home.packages = [ pkgs.nix ];
                        systemd.user.startServices = lib.mkForce false;
                    }
                ];
            };

            rootfs = pkgs.runCommand "devenv-home-rootfs" { } ''
                mkdir -p \
                    "$out/bin" \
                    "$out/etc" \
                    "$out/root" \
                    "$out/tmp" \
                    "$out/usr"
                chmod 1777 "$out/tmp"

                ln -s ${pkgs.bashInteractive}/bin/bash "$out/bin/sh"
                ln -s ${pkgs.cacert}/etc/ssl/certs "$out/etc/ssl-certs"
                ln -s ${pkgs.glibc}/lib "$out/lib"
                ln -s ${pkgs.glibc}/lib64 "$out/lib64"
                ln -s ${pkgs.glibc.dev}/include "$out/usr/include"

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
                maxLayers = 120;
                metadata = {
                    created_by = "home-manager package closure";
                };
            };
        in
        nix2containerLib.buildImage {
            # The load script selects the semantic destination tag with
            # copyTo. This internal tag is not written to Podman.
            name = "localhost/devenv/nix-home-manager-env";
            tag = "unversioned";
            copyToRoot = rootfs;
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
        };
    in
    {
        packages = forAllSystems (system:
            {
                home-manager = home-manager.packages.${system}.home-manager;
            }
            // nixpkgs.lib.optionalAttrs (nixpkgs.lib.systems.elaborate system).isLinux {
                devenv-home-base = mkDevenvHomeBase system;
            }
        );

        apps = forAllSystems (system: {
            home-manager = {
                type = "app";
                program = "${self.packages.${system}.home-manager}/bin/home-manager";
            };
        });

        homeConfigurations.default = 
            home-manager.lib.homeManagerConfiguration {
                pkgs = pkgsFor builtins.currentSystem;
                modules = [ ./home/home.nix ];
            };
    };
}
