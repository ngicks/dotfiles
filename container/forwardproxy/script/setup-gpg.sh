#!/usr/bin/env bash
# Create a DEDICATED gpg keyring + key that holds ONLY the proxy-secret key, so
# the agent socket forwarded into the container can decrypt nothing else.
#
# The dedicated agent caches NOTHING (ttl 0) and prompts on every proxy
# (re)start. Because the agent is a daemon with no terminal (and the host may
# have no GUI display, e.g. WSL2), its pinentry-program is the pinentry-tmux
# wrapper: it spawns a dedicated tmux server, registers that pane's tty with the
# agent (GPG_TTY + updatestartuptty), and draws curses pinentry there. keep-tty
# pins every prompt to that pane regardless of the client's empty TTY.
#
# Env knobs:
#   FP_DIR              base dir            (default ~/.config/forwardproxy)
#   FP_PINENTRY_CURSES  curses pinentry     (default ~/.nix-profile/bin/pinentry-curses)
set -eCu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
FP_DIR="${FP_DIR:-$HOME/.config/forwardproxy}"
FP_GNUPGHOME="${FP_GNUPGHOME:-$FP_DIR/gnupg}"
FP_PINENTRY_CURSES="${FP_PINENTRY_CURSES:-$HOME/.nix-profile/bin/pinentry-curses}"
FP_PINENTRY="$FP_DIR/pinentry-tmux"   # the wrapper, installed below; agent runs this
KEY_UID="forwardproxy (proxy secret) <forwardproxy@localhost>"

require_protected_secret_keys() {
  local keygrips

  keygrips=$(
    gpg --homedir "$FP_GNUPGHOME" --with-colons --with-keygrip \
      --list-secret-keys "$KEY_UID" \
      | awk -F: '$1 == "grp" { print $10 }'
  )
  if [ -z "$keygrips" ]; then
    echo "error: no secret keygrips found for $KEY_UID" >&2
    exit 1
  fi

  # Clear any passphrase cached during key creation. If the secret key can then
  # be exported with an empty loopback passphrase, it was generated unprotected.
  gpgconf --homedir "$FP_GNUPGHOME" --kill gpg-agent || true
  if gpg --homedir "$FP_GNUPGHOME" --batch --yes --pinentry-mode loopback \
    --passphrase '' --export-secret-keys "$KEY_UID" > /dev/null 2>&1; then
    echo "error: dedicated forwardproxy key is not passphrase-protected." >&2
    echo "       Delete $FP_GNUPGHOME and rerun this script, then enter a non-empty passphrase." >&2
    exit 1
  fi
}

primary_fingerprint() {
  gpg --homedir "$FP_GNUPGHOME" --with-colons --list-secret-keys "$KEY_UID" \
    | awk -F: '$1 == "fpr" { print $10; exit }'
}

has_encryption_subkey() {
  gpg --homedir "$FP_GNUPGHOME" --with-colons --list-secret-keys "$KEY_UID" \
    | awk -F: '$1 == "ssb" && $12 ~ /e/ { found = 1 } END { exit found ? 0 : 1 }'
}

if [ ! -x "$FP_PINENTRY_CURSES" ]; then
  echo "warning: curses pinentry not found at $FP_PINENTRY_CURSES" >&2
  echo "         add pkgs.pinentry-curses to nix-craft/home/home.nix and rebuild," >&2
  echo "         or set FP_PINENTRY_CURSES=/path/to/pinentry-curses." >&2
fi
if [ ! -f "$script_dir/pinentry-tmux" ]; then
  echo "error: pinentry-tmux wrapper not found next to this script" >&2
  exit 1
fi

mkdir -p "$FP_DIR"
install -d -m 700 "$FP_GNUPGHOME"

# Install the pinentry-program the agent runs. It owns the dedicated tmux server
# and the GPG_TTY/updatestartuptty handshake; the agent only needs its path.
install -m 0755 "$script_dir/pinentry-tmux" "$FP_PINENTRY"

# No caching: prompt on every decryption (i.e. every proxy start). keep-tty makes
# the agent ignore the forwarded client's empty TTY and use the startup tty the
# wrapper registers (the dedicated tmux pane). No keep-display: this is terminal,
# not GUI, pinentry.
cat >| "$FP_GNUPGHOME/gpg-agent.conf" <<EOF
pinentry-program $FP_PINENTRY
keep-tty
default-cache-ttl 0
max-cache-ttl 0
EOF

# Cert-only primary key + encryption subkey WITH a passphrase (so each start
# really prompts). OpenPGP primary keys certify user IDs; encryption belongs on a
# subkey. This keyring will contain nothing else. The passphrase prompt uses the
# pinentry above, so run this where the GUI can appear (or inside tmux/zellij).
if ! gpg --homedir "$FP_GNUPGHOME" --list-keys "$KEY_UID" > /dev/null 2>&1; then
  gpg --homedir "$FP_GNUPGHOME" \
    --quick-generate-key "$KEY_UID" default cert never
fi

if ! has_encryption_subkey; then
  fpr=$(primary_fingerprint)
  if [ -z "$fpr" ]; then
    echo "error: could not find primary fingerprint for $KEY_UID" >&2
    exit 1
  fi
  gpg --homedir "$FP_GNUPGHOME" \
    --quick-add-key "$fpr" default encr never
fi

require_protected_secret_keys

gpg --homedir "$FP_GNUPGHOME" --armor --export "$KEY_UID" >| "$FP_DIR/pubkey.asc"

# Let the systemd unit be the canonical launcher (it binds the explicit extra
# socket); kill any agent this script auto-started for the homedir.
gpgconf --homedir "$FP_GNUPGHOME" --kill gpg-agent || true

cat <<EOF

dedicated keyring : $FP_GNUPGHOME
public key        : $FP_DIR/pubkey.asc
pinentry          : $FP_PINENTRY  (dedicated tmux, asked on every proxy start, nothing cached)
                    answer prompts with: tmux -S "\${XDG_RUNTIME_DIR:-/tmp}/forwardproxy/pinentry.tmux.sock" attach

Next, encrypt your domain password to this key (it becomes the ONLY secret used
to mint a Kerberos ticket via kinit; nothing else is stored). Pipe it in so it
never lands on disk -- printf avoids a trailing newline:

  printf '%s' 'DOMAIN_PASSWORD' | \\
    gpg --homedir '$FP_GNUPGHOME' -e -r '$KEY_UID' -o '$FP_DIR/secret.gpg'

Then start the dedicated agent + proxy:

  systemctl --user daemon-reload
  systemctl --user start forwardproxy-gpg-agent.service forwardproxy.service
EOF
