{ config, pkgs, ... }:

{
  imports = [
    ./tmux
    ./zellij
    ./wezterm
    ./nvim
    ./mise
    ./zsh
  ];

  home.username = builtins.getEnv "USER";
  home.homeDirectory = builtins.getEnv "HOME";

  home.stateVersion = "25.11";

  home.sessionPath = [
    "$HOME/.nix-profile/bin"
    "$HOME/.local/bin"
  ];

  home.sessionVariables = {
      MISE_TRUSTED_CONFIG_PATHS = "$HOME/.config/mise/mise.toml:$HOME/.dotfiles/config/mise/mise.toml";
    };

  xdg.configFile."nix" = {
    source = ../../config/nix;
    recursive = true;
  };

  programs = {
    lazygit = import ./lazygit;
    git = {
      enable = true;
    };
  };

  home.packages = with pkgs; [
    # core runtimes (base packages, mise handles version management)
    nodejs         # Node.js runtime
    deno
    bun            # JavaScript runtime & package manager
    python3
    uv             # Python package installer
    ruby
    rustup
    go

    # CLI Utilities (not managed by mise/modules)
    ripgrep        # Fast grep (rg)
    bat            # Better cat
    eza            # Better ls (replaces exa)
    fd             # Better find
    bottom         # System monitor (btm)
    dust           # Disk usage (dust)
    procs          # Better ps
    sd             # Better sed
    hyperfine      # Benchmarking
    fzf            # Fuzzy finder
    yazi           # File manager
    stow           # Symlink manager

    # Kubernetes/DevOps
    kubectl        # Kubernetes CLI
    kubernetes-helm # Helm
    kompose        # Docker Compose to K8s
    kops           # K8s cluster management
    sops           # Secret encryption
    age            # Encryption tool
    nerdctl        # containerd CLI

    # Git Tools
    gh             # GitHub CLI
    glab           # GitLab CLI

    # Protobuf
    protobuf       # protoc compiler
    buf            # Protobuf build tool
    protoc-gen-go  # Go protobuf generator
    protoc-gen-go-grpc # Go gRPC generator
    grpc-gateway   # grpc-gateway generators

    # IaC/Automation
    ansible        # Automation tool

    # Yazi optional dependencies (preview & navigation)
    ffmpeg         # video thumbnails
    poppler        # PDF preview
    imagemagick    # image/font preview
    chafa          # ASCII image preview fallback
    resvg          # SVG preview
    zoxide         # directory history navigation

    # System/Build Tools (ported from apt deps)
    gnupg          # GPG encryption
    wget           # Download utility
    curl           # HTTP client
    gnumake        # Make build tool
    gcc            # GNU C compiler
    jq             # JSON processor
    xsel           # Clipboard utility
    p7zip          # 7-Zip archiver
    libyaml        # YAML library
    zlib           # Compression library
  ];
}
