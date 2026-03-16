{
    description = "dotfiles (home-manager, Linux/macOS)";

    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
        home-manager = {
            url = "github:nix-community/home-manager";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        moonbit-overlay = {
            url = "github:moonbit-community/moonbit-overlay";
            inputs.nixpkgs.follows = "nixpkgs";
        };
    };

    outputs = { self, nixpkgs, home-manager, moonbit-overlay, ... }:
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
            overlays = [
                moonbit-overlay.overlays.default
            ];
        };
    in
    {
        packages = forAllSystems (system: {
            home-manager = home-manager.packages.${system}.home-manager;
        });

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
