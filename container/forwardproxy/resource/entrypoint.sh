#!/bin/sh
# Decrypt the domain password via the forwarded dedicated gpg-agent, pipe it
# STRAIGHT into kinit to mint a Kerberos TGT, then discard it. A local Squid
# forwards everything upstream and authenticates to the corporate proxy with the
# *ticket* (Negotiate/SPNEGO); it never sees the password. The ticket is renewed
# from itself until the realm's renewable lifetime ends, then the container exits
# so systemd restarts it -> one fresh pinentry.
set -eu
set -o pipefail 2>/dev/null || true

: "${REALM:?set REALM (e.g. EXAMPLE.COM)}"
: "${PRINCIPAL:?set PRINCIPAL (e.g. user or user@EXAMPLE.COM)}"
: "${UPSTREAM_HOST:?set UPSTREAM_HOST (FQDN of the corporate proxy)}"
: "${UPSTREAM_PORT:=8080}"
: "${BIND:=0.0.0.0}"
: "${PORT:=3128}"
: "${PROXY_ACL:=}"                  # space/comma CIDR list; empty => allow all
: "${KDC:=}"                        # optional; else DNS SRV discovery
: "${TICKET_RENEWABLE:=7d}"         # requested renewable lifetime
: "${RENEW_INTERVAL:=28800}"        # 8h; must be < ticket lifetime (~10h)
: "${SECRET_GPG:=/secrets/secret.gpg}"
: "${PUBKEY:=/secrets/pubkey.asc}"
: "${FORWARDPROXY_GPG_DEBUG:=0}"

export KRB5CCNAME="${KRB5CCNAME:-FILE:/run/krb5cc}"
agent_socket="${GNUPGHOME}/S.gpg-agent"

# Import the public key so gpg can map the ciphertext to a keygrip and ask the
# forwarded host agent to decrypt. (The private key stays on the host.)
if [ -f "$PUBKEY" ]; then
  gpg --batch --quiet --import "$PUBKEY" 2>/dev/null || true
fi
if [ ! -S "$agent_socket" ]; then
  echo "error: forwarded gpg-agent socket not found at $agent_socket" >&2
  echo "       bind-mount the dedicated agent's extra socket there." >&2
  exit 1
fi
if [ "$FORWARDPROXY_GPG_DEBUG" = 1 ]; then
  echo "gpg debug: GNUPGHOME=$GNUPGHOME" >&2
  ls -l "$agent_socket" >&2 || true
  gpgconf --list-dirs >&2 || true
  gpg --batch --with-colons --list-packets "$SECRET_GPG" >&2 || true
  gpg --batch --with-colons --with-keygrip --list-public-keys >&2 || true
fi

# krb5.conf: a mounted one wins; otherwise generate a minimal one from env.
if [ ! -s /etc/krb5.conf ]; then
  {
    echo "[libdefaults]"
    echo "    default_realm = ${REALM}"
    echo "    dns_lookup_kdc = true"
    echo "    dns_lookup_realm = false"
    echo "    forwardable = true"
    echo "    renewable = true"
    [ -n "$KDC" ] && printf '[realms]\n    %s = {\n        kdc = %s\n    }\n' "$REALM" "$KDC"
  } > /etc/krb5.conf
fi

# Render the Squid config into tmpfs and append the client ACL block. Squid
# requires acl definitions before the http_access lines that use them, so both
# go at the very end (the template's directives reference neither).
run_conf=/run/squid.conf
umask 077
sed \
  -e "s#@BIND@#${BIND}#g" \
  -e "s#@PORT@#${PORT}#g" \
  -e "s#@UPSTREAM_HOST@#${UPSTREAM_HOST}#g" \
  -e "s#@UPSTREAM_PORT@#${UPSTREAM_PORT}#g" \
  /etc/squid/squid.conf.template > "$run_conf"
{
  if [ -n "$PROXY_ACL" ]; then
    printf 'acl localnet src %s\n' "$(printf '%s' "$PROXY_ACL" | tr ',' ' ')"
    echo "http_access allow localnet"
  else
    echo "warning: PROXY_ACL empty -> Squid allows ALL clients" >&2
    echo "http_access allow all"
  fi
  echo "http_access deny all"
} >> "$run_conf"

# --- mint the ticket: the secret only ever transits this pipe, never a var/file ---
# Do not use --batch here: decrypting should be allowed to trigger host-side
# pinentry through the forwarded agent socket. --no-tty keeps container gpg from
# trying to interact with the container service's nonexistent terminal.
gpg_args="--no-tty --pinentry-mode ask --quiet"
if [ "$FORWARDPROXY_GPG_DEBUG" = 1 ]; then
  gpg_args="$gpg_args --verbose --debug-level advanced --status-fd 2"
fi
# kinit MUST read the password from the pipe (stdin), not interactively. Without
# --password-file=STDIN, kinit's prompter opens /dev/tty when a terminal exists
# and ignores the piped secret entirely (that is the "Password for ...:" prompt
# you see when running this by hand); with no tty it only falls back to stdin by
# luck. --password-file=STDIN makes it deterministic and silent in both cases.
gpg $gpg_args --decrypt "$SECRET_GPG" \
  | kinit --password-file=STDIN -r "$TICKET_RENEWABLE" "$PRINCIPAL"
echo "kinit OK; password discarded, starting squid" >&2

# Fail fast on a bad rendered config instead of looping on a dead squid.
squid -k parse -f "$run_conf"

# -N: stay in the foreground (no self-daemonize) so we keep its PID; -d1: log to
# stderr. Squid re-reads KRB5CCNAME for each peer authentication, so renewing the
# ticket in place (below) is picked up without restarting squid.
squid -N -d 1 -f "$run_conf" &
squid_pid=$!
trap 'kill "$squid_pid" 2>/dev/null || true' TERM INT

# Renew from the ticket itself (no password). When the renewable lifetime is
# exhausted, exit so systemd restarts us -> one fresh pinentry.
while sleep "$RENEW_INTERVAL"; do
  kill -0 "$squid_pid" 2>/dev/null || { echo "squid exited" >&2; exit 1; }
  if ! kinit -R 2>/dev/null; then
    echo "renewable lifetime exhausted; exiting for restart (fresh pinentry)" >&2
    break
  fi
done
kill "$squid_pid" 2>/dev/null || true
exit 1
