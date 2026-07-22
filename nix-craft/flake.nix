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

        mkDevenvHomeBase = system: import ./devenv-home-base.nix {
            pkgs = pkgsFor system;
            inherit home-manager system;
            nix2containerLib = nix2container.packages.${system}.nix2container;
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
