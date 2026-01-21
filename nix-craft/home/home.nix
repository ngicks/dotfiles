{ config, pkgs, ... }:

{
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

  imports = [
    ./fzf
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
    deno
    bun
    python3
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

    # Media
    ffmpeg         # video thumbnails
    poppler        # PDF preview
    imagemagick    # image/font preview
    chafa          # ASCII image preview fallback
    resvg          # SVG preview

    # System/Build Tools
    gnupg          # GPG encryption
    gnumake        # Make build tool
    gcc            # GNU C compiler
    jq             # JSON processor
    xsel           # Clipboard utility
    libyaml        # YAML library

    # Traditional Unix utilities (container compatibility)
    gawk           # GNU awk
    gnused         # GNU sed
    gnugrep        # GNU grep

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
  ];
}
