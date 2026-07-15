{ ... }:

{
  # The dotfiles server loads ~/.config/dotfilesmgr/.env on startup; manage
  # it declaratively here. See config/dotfilesmgr/.env.example for the full
  # set of supported keys.
  xdg.configFile."dotfilesmgr/.env".text = ''
    # Enable automatic devenv image rebuilds when the upstream checkout advances.
    DOTFILES_SERVER_AUTO_BUILD=1
  '';
}
