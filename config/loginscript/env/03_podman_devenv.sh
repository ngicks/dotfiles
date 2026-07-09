# Auto-wire podman inside the devenv container on first login: link host dist
# (the host image store is wired in at runtime via STORAGE_OPTS, set by
# devenv/scripts/opts.d/07-podman.sh), then bring the interpolated conf onto PATH.
if [[ "${DEVENV_PODMAN:-}" == "1" ]] && [[ ! -d "$HOME/.config/containers" ]] && command -v podman-static-dist >/dev/null 2>&1; then
  if podman-static-dist link; then
    if [[ -f "$HOME/.config/containers/path.sh" ]]; then
      . "$HOME/.config/containers/path.sh"
    fi
  fi
fi
