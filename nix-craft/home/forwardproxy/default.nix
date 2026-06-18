{ lib, ... }:

{
  xdg.configFile."forwardproxy" = {
    source = ../../../config/forwardproxy;
    recursive = true;
  };

  home.activation.reloadForwardproxyQuadlet = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if command -v systemctl >/dev/null 2>&1; then
      systemctl --user daemon-reload || true
    fi
  '';
}
