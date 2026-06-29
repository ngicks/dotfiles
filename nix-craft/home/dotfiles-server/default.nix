{ ... }:

{
  # The dotfiles server loads ~/.config/dotfiles-server/.env on startup; manage
  # it declaratively here. See config/dotfiles-server/.env.example for the full
  # set of supported keys.
  xdg.configFile."dotfiles-server/.env".text = ''
    # Enable automatic devenv image rebuilds when the upstream checkout advances.
    DOTFILES_SERVER_AUTO_BUILD=1
  '';
}
