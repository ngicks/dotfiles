#!/usr/bin/env bash
# Create a DEDICATED gpg keyring + key that holds ONLY the proxy-secret key, so
# the agent socket forwarded into the container can decrypt nothing else.
#
# The dedicated agent caches NOTHING (ttl 0) and asks via GUI pinentry on every
# proxy (re)start. keep-display/keep-tty make it ignore the container client's
# empty DISPLAY/TTY and use the daemon's own display for the prompt.
#
# Env knobs:
#   FP_DIR       base dir       (default ~/.config/forwardproxy)
#   FP_PINENTRY  pinentry path  (default ~/.nix-profile/bin/pinentry-qt)
set -eCu

FP_DIR="${FP_DIR:-$HOME/.config/forwardproxy}"
FP_GNUPGHOME="${FP_GNUPGHOME:-$FP_DIR/gnupg}"
FP_PINENTRY="${FP_PINENTRY:-$HOME/.nix-profile/bin/pinentry-qt}"
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

if [ ! -x "$FP_PINENTRY" ]; then
  echo "warning: GUI pinentry not found at $FP_PINENTRY" >&2
  echo "         add pkgs.pinentry-qt to nix-craft/home/home.nix and rebuild," >&2
  echo "         or set FP_PINENTRY=/path/to/pinentry-qt." >&2
fi

mkdir -p "$FP_DIR"
install -d -m 700 "$FP_GNUPGHOME"

# No caching: prompt via GUI pinentry on every decryption (i.e. every proxy
# start). keep-display/keep-tty: ignore the forwarded client's env, use ours.
cat >| "$FP_GNUPGHOME/gpg-agent.conf" <<EOF
pinentry-program $FP_PINENTRY
keep-display
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
pinentry          : $FP_PINENTRY  (asked on every proxy start, nothing cached)

Next, encrypt your domain password to this key (it becomes the ONLY thing kpx
uses to mint a Kerberos ticket; nothing else is stored). Pipe it in so it never
lands on disk -- printf avoids a trailing newline:

  printf '%s' 'DOMAIN_PASSWORD' | \\
    gpg --homedir '$FP_GNUPGHOME' -e -r '$KEY_UID' -o '$FP_DIR/secret.gpg'

Then start the dedicated agent + proxy:

  systemctl --user daemon-reload
  systemctl --user start forwardproxy-gpg-agent.service forwardproxy.service
EOF
