#!/bin/sh
# Decrypt the domain password via the forwarded dedicated gpg-agent, pipe it
# STRAIGHT into kinit to mint a Kerberos TGT, then discard it. kpx authenticates
# upstream with the *ticket* (Negotiate); it never sees the password. The ticket
# is renewed from itself until the realm's renewable lifetime ends, then the
# container exits so systemd restarts it -> one fresh pinentry.
set -eu
set -o pipefail 2>/dev/null || true

: "${REALM:?set REALM (e.g. EXAMPLE.COM)}"
: "${PRINCIPAL:?set PRINCIPAL (e.g. user or user@EXAMPLE.COM)}"
: "${UPSTREAM_HOST:?set UPSTREAM_HOST (FQDN of the corporate proxy)}"
: "${UPSTREAM_PORT:=8080}"
: "${PROXY_SPN:=HTTP}"
: "${BIND:=0.0.0.0}"
: "${PORT:=3128}"
: "${PROXY_ACL:=}"                  # space/comma CIDR list; empty => allow all
: "${KDC:=}"                        # optional; else DNS SRV discovery
: "${TICKET_RENEWABLE:=7d}"         # requested renewable lifetime
: "${RENEW_INTERVAL:=28800}"        # 8h; must be < ticket lifetime (~10h)
: "${KPX_RESTART_ON_RENEW:=1}"      # restart kpx after renew so it reloads ticket
: "${SECRET_GPG:=/secrets/secret.gpg}"
: "${PUBKEY:=/secrets/pubkey.asc}"

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

# Render the kpx config into tmpfs and append the ACL block.
run_conf=/run/kpx.yaml
umask 077
sed \
  -e "s#@BIND@#${BIND}#g" \
  -e "s#@PORT@#${PORT}#g" \
  -e "s#@SPN@#${PROXY_SPN}#g" \
  -e "s#@REALM@#${REALM}#g" \
  -e "s#@UPSTREAM_HOST@#${UPSTREAM_HOST}#g" \
  -e "s#@UPSTREAM_PORT@#${UPSTREAM_PORT}#g" \
  /etc/kpx/kpx.yaml.template > "$run_conf"
{
  echo ""
  echo "acl:"
  if [ -n "$PROXY_ACL" ]; then
    for cidr in $(printf '%s' "$PROXY_ACL" | tr ',' ' '); do
      printf '  - %s\n' "$cidr"
    done
  else
    echo "warning: PROXY_ACL empty -> kpx allows ALL clients" >&2
  fi
} >> "$run_conf"

# --- mint the ticket: the secret only ever transits this pipe, never a var/file ---
gpg --batch --quiet --decrypt "$SECRET_GPG" \
  | kinit -r "$TICKET_RENEWABLE" "$PRINCIPAL"
echo "kinit OK; password discarded, starting kpx" >&2

start_kpx() { kpx -c "$run_conf" & kpx_pid=$!; }
start_kpx

# Renew from the ticket itself (no password). When the renewable lifetime is
# exhausted, exit so systemd restarts us -> one fresh pinentry.
while sleep "$RENEW_INTERVAL"; do
  kill -0 "$kpx_pid" 2>/dev/null || { echo "kpx exited" >&2; exit 1; }
  if kinit -R 2>/dev/null; then
    if [ "$KPX_RESTART_ON_RENEW" = 1 ]; then
      kill "$kpx_pid" 2>/dev/null || true
      wait "$kpx_pid" 2>/dev/null || true
      start_kpx
    fi
  else
    echo "renewable lifetime exhausted; exiting for restart (fresh pinentry)" >&2
    break
  fi
done
kill "$kpx_pid" 2>/dev/null || true
exit 1
