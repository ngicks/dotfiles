{ config, pkgs, ... }:

let
  goimports = pkgs.runCommand "goimports" { } ''
    mkdir -p $out/bin
    ln -s ${pkgs.gotools}/bin/goimports $out/bin/goimports
  '';
in
{
  home.username = builtins.getEnv "USER";
  home.homeDirectory = builtins.getEnv "HOME";

  home.stateVersion = "26.05";

  home.sessionPath = [
    "$HOME/.nix-profile/bin"
    "$HOME/.local/bin"
  ];

  home.sessionVariables = {
      MISE_TRUSTED_CONFIG_PATHS = "$HOME/.config/mise/mise.toml:$HOME/.dotfiles/config/mise/mise.toml";
      LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
      LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
        # rust and realted need this
        pkgs.stdenv.cc.cc.lib
      ];

      # Point Playwright at the nix-provided browsers (read-only nix store) and
      # skip the host-requirement check, which fails on non-NixOS/WSL.
      PLAYWRIGHT_BROWSERS_PATH = "${pkgs.playwright-driver.browsers}";
      PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS = "true";
  };

  home.file.".local/bin/pinentry.sh" = {
    source = ../../scripts/pinentry.sh;
    executable = true;
  };

  # golangci-lint v2 must outrank mise's v1/v2 and any stale $GOBIN copy on PATH.
  # Drop the nix binary into the existing ~/.local/bin/override dir, which
  # env/99_override.sh already prepends to PATH, so the bare `golangci-lint`
  # resolves here. (mise keeps its v1/v2 go-backend entries for nvim's detection.)
  home.file.".local/bin/override/golangci-lint".source =
    "${pkgs.golangci-lint}/bin/golangci-lint";

  xdg.configFile."nix" = {
    source = ../../config/nix;
    recursive = true;
  };

  # Quadlet units live here, NOT in ~/.config/containers: the static podman
  # installer (builder/podman-static-dist/install.sh) replaces ~/.config/containers with
  # a symlink to its bundled etc/containers and aborts if it is a real directory.
  # config/environment.d/podman.conf sets QUADLET_UNIT_DIRS to this path so the
  # rootless quadlet generator picks them up.
  xdg.configFile."containers-quadlet" = {
    source = ../../config/containers-quadlet;
    recursive = true;
  };

  xdg.configFile."environment.d" = {
    source = ../../config/environment.d;
    recursive = true;
  };

  xdg.configFile."systemd" = {
    source = ../../config/systemd;
    recursive = true;
  };

  imports = [
    ./cmdman
    ./crabswarm
    ./dotfilesmgr
    ./fzf
    ./forwardproxy
    ./lazygit
    ./mise
    ./nvim
    ./starship
    ./tmux
    ./wezterm
    ./zellij
    ./zsh
  ];

  programs = {
    git = {
      enable = true;
    };
  };

  home.packages = with pkgs; [
    # core runtimes
    nodejs
    pnpm           # JS package manager (frontend dep management)
    deno
    bun
    (python3.withPackages (ps: [ ps.setuptools ]))
    uv
    ruby
    rustup
    go

    # CLI Utilities (not managed by mise/modules)
    ripgrep        # Fast grep (rg)
    bat            # Better cat
    eza            # Better ls (replaces exa)
    fd             # Better find
    htop           # Better top
    bottom         # Better top#2
    dust           # Disk usage (dust)
    procs          # Better ps
    sd             # Better sed
    hyperfine      # Benchmarking
    just           # Command runner
    yazi           # File manager
    stow           # Symlink manager
    zoxide         # directory history navigation

    # Kubernetes/DevOps
    kubectl        # Kubernetes CLI
    kubernetes-helm # Helm
    kompose        # Docker Compose to K8s
    kops           # K8s cluster management
    sops           # Secret encryption
    age            # Encryption tool
    nerdctl        # containerd CLI
    skopeo         # OCI/container image inspection and copy

    # Git Tools
    gh                     # GitHub CLI
    glab                   # GitLab CLI
    git-credential-manager # Git Credential Manager (gcm)
    pass                   # Unix password store
    git-lfs                # Git Large File Storage

    # Protobuf
    protobuf       # protoc compiler
    buf            # Protobuf build tool
    protoc-gen-go  # Go protobuf generator
    protoc-gen-go-grpc # Go gRPC generator
    protoc-gen-connect-go # Connect-RPC Go generator
    protoc-gen-es # ES/TS protobuf generator
    grpc-gateway   # grpc-gateway generators

    # IaC/Automation
    ansible        # Automation tool

    # Media
    ffmpeg         # video thumbnails
    poppler        # PDF preview
    imagemagick    # image/font preview
    chafa          # ASCII image preview fallback
    resvg          # SVG preview

    # LSP Servers
    lua-language-server
    vscode-langservers-extracted  # html, cssls, jsonls
    marksman
    taplo
    pyright
    (lib.hiPrio rust-analyzer)    # wins over rustup's proxy binary
    (lib.hiPrio typescript-go)    # ts7 toolchain; its tsc wins over the TypeScript fallback below
    # kept until tsgo proves itself; remove once it does
    typescript-language-server
    typescript                    # peer dep for ts_ls

    # Formatters / Linters
    kdlfmt
    prettier
    stylua
    xmlformat                     # xmlformatter

    # DAP
    vscode-js-debug               # js-debug binary for Node.js debugging

    # Frontend / Browser testing
    # Playwright browsers (chromium/firefox/webkit) for the playwright npm pkg
    # managed via pnpm. Driver pinned at v${pkgs.playwright-driver.version}; keep the project's
    # `playwright` dep on the same version or browsers won't be found.
    playwright-driver.browsers

    # Rust Tools
    cargo-binstall # Prebuilt Rust binary installer (used by mise cargo backend)

    # Go Development Tools
    gopls
    goimports # extracted from gotools. See above.
    gofumpt
    go-tools       # staticcheck
    golangci-lint  # v2; prioritized over mise/$GOBIN via ~/.local/bin/override (see env/99_override.sh)
    delve
    gotests
    gomodifytags
    impl
    iferr

    # System/Build Tools
    gnupg          # GPG encryption
    pinentry-qt    # Qt pinentry for GPG (also bundles a bin/pinentry-curses)
    # terminal pinentry; used by forwardproxy's dedicated tmux agent. pinentry-qt
    # ships its own bin/pinentry-curses, so hiPrio lets this dedicated package win
    # the buildEnv collision instead of failing the home-manager-path build.
    (lib.hiPrio pinentry-curses)
    gnumake        # Make build tool
    gcc            # GNU C compiler
    glibc
    llvmPackages.libclang  # libclang for bindgen (cargo builds)
    stdenv.cc.cc.lib       # libstdc++ (needed by libclang)
    jq             # JSON processor
    yq             # YAML/JSON processor
    xsel           # Clipboard utility
    libyaml        # YAML library

    # Traditional Unix utilities (container compatibility)
    gawk           # GNU awk
    gnused         # GNU sed
    gnugrep        # GNU grep
    watch          # periodic command runner (procps)

    # Terminal support
    ncurses        # Terminfo database for less/vim/etc

    # Compression utilities
    zlib
    xz             # XZ/LZMA compression
    zip            # Zip creation
    unzip          # Zip extraction
    p7zip          # 7-Zip archiver
    zstd           # Zstandard compression

    # Networking utilities
    curl           # HTTP client
    wget           # Download utility
    netcat         # Network utility (nc)
    dig            # DNS lookup
    iproute2       # ip, ss (Linux networking)
    traceroute     # Network path tracing

    libkrun
  ] ++ lib.optionals stdenv.isLinux [
    # KVM/libvirt tooling for devenv containers. The launcher can opt into
    # /dev/kvm and persistent libvirt image storage with DEVENV_KVM=1.
    libvirt        # virsh, libvirtd
    qemu_kvm       # qemu-system-* with KVM support
    virt-manager   # GUI + virt-install/virt-clone/virt-xml
    passt          # user-mode networking backend with <portForward> support
    # Not gonna use Vagrant because it is HashiCorp's (not an OSS).
    lima           # limactl: QEMU-backed Linux VMs, auto file-share + port-forward
    incus          # LXD fork: system containers + QEMU VMs (needs incusd daemon)
  ];
}
