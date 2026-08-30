if [[ -o login ]] && [[ "${IN_CONTAINER:-}" != "1" ]]; then
  if command -v cmdman > /dev/null 2>&1 && command -v crabswarm > /dev/null 2>&1; then
    if [ "$(cmdman inspect crabswarm-serve --format '{{.State}}' 2> /dev/null)" != "running" ]; then
      cmdman start crabswarm-serve > /dev/null 2>&1 \
        || cmdman run --name crabswarm-serve --rm --restart always -- crabswarm serve \
        || echo "loginscript: failed to start crabswarm-serve under cmdman" >&2
    fi
  fi
fi
