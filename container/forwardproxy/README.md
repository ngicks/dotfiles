# forwardproxy

A credential-less **Kerberos/Negotiate** forward proxy that runs as a
**host-wide service**. It authenticates to the corporate proxy on your behalf and
exposes an unauthenticated local endpoint, so nothing on the host ever carries
`HTTP_PROXY=http://user:password@...` in any env var, build-arg, or image layer.

- Host processes: `HTTP_PROXY=http://127.0.0.1:3128`
- Containers (devenv): `HTTP_PROXY=http://host.containers.internal:3128`

## How the secret is handled

Your domain **password lives only in a gpg-encrypted file at rest**. It is never
stored decrypted anywhere. At each (re)start the container:

1. Decrypts the password through a forwarded, **dedicated single-key gpg-agent**
   extra socket. The agent prompts via a **dedicated tmux server** (terminal
   pinentry, nothing cached) — see [Answering the pinentry prompt](#answering-the-pinentry-prompt).
2. Pipes it **straight into `kinit`** — never into a variable, env, or file — to
   mint a Kerberos **ticket (TGT)**, then the password is gone from memory.
3. Runs **Squid**, which forwards everything to the corporate proxy and
   authenticates to it with the **ticket** (`cache_peer ... login=NEGOTIATE
   auth-no-keytab`, Negotiate/SPNEGO). Squid never sees the password.
4. Renews the ticket **from itself** (no password) until the realm's renewable
   lifetime ends, then exits so systemd restarts it → one fresh pinentry.

This is exactly Kerberos's design: the password's only job is to obtain a
short-lived token; the token does the talking.

The gpg-agent is **dedicated** (a separate keyring holding one encrypt-only key)
because the extra socket restricts *commands*, not *which keys* it can use — a
shared agent would let a compromised container decrypt/sign with all your keys.

```
dedicated gpg-agent  (separate GNUPGHOME, ONE encrypt-only key)
        │  S.gpg-agent.extra  (restricted commands, single key)
        ▼  decrypt password ──pipe──► kinit ──► Kerberos ticket (TGT)
┌──────────────────────────┐  Negotiate  ┌───────────────────────┐
│ forwardproxy (squid)     │  (ticket)   │ corporate Squid       │
│  Network=host  :3128     │ ──────────► │ (UPSTREAM_HOST:PORT)  │
└──────────────────────────┘             └───────────────────────┘
   ▲ 127.0.0.1:3128 (host tools)
   ▲ host.containers.internal:3128 (containers)
```

It runs with **host networking** so squid sees real client source IPs, which makes
the ACL meaningful (rootless published ports masquerade the source IP and would
defeat it).

## Layout

```
Containerfile               image definition (build context is this dir)
tag                         fixed image tag, read by build.sh
resource/                   files COPYed into the image
  entrypoint.sh
  squid.conf.template
script/                     host-side scripts/examples (not shipped in the image)
  build.sh
  setup-gpg.sh
  pinentry-tmux             agent pinentry-program; installed into ~/.config/forwardproxy
config/containers/systemd/forwardproxy.container
                            Home Manager-installed Quadlet unit
config/systemd/user/forwardproxy-gpg-agent.service
                            Home Manager-installed dedicated gpg-agent unit
config/systemd/user/forwardproxy.service.d/10-office-only.conf
                            skips the generated Quadlet service off-office
config/environment.d/podman.conf
                            points Quadlet/systemd generators at static podman
config/forwardproxy/forwardproxy.env.example
                            template for local, untracked office settings
```

## 1. Build the image

```sh
./container/forwardproxy/script/build.sh
```

The image is tagged `localhost/devenv/forwardproxy:<tag>` where `<tag>` is read
from the `tag` file (keep it in sync with `Image=` in `forwardproxy.container`).
The image is a thin Alpine layer that installs **squid** and **heimdal** (kinit)
from Alpine packages — no Go toolchain, no mise, no downloaded binary. Because the
packages exist for every Alpine arch, the image now builds on **arm64** too (the
old kpx-based image was amd64-only). Podman forwards the host's proxy env into the
build automatically, so no proxy flags are needed.

## 2. Create the dedicated key + encrypted password

Prereq: a curses pinentry. Add `pinentry-curses` to `nix-craft/home/home.nix`
packages and rebuild — the daemon can't use the tmux/zellij popup wrappers (it
has no attached session), and the host may have no GUI display (e.g. WSL2). `tmux`
is also required (already in the dotfiles).

`setup-gpg.sh` builds a separate keyring under `~/.config/forwardproxy/gnupg`
holding a single **passphrase-protected** proxy key with an encryption subkey,
**installs the `pinentry-tmux` wrapper** into `~/.config/forwardproxy/`, writes an
agent config with **no caching** (prompts on every proxy start) that uses it, and
exports the public key. Set `FP_PINENTRY_CURSES` to override the real curses
pinentry path. Enter a non-empty passphrase when GPG asks; the script fails if the
dedicated key is left unprotected.

```sh
./container/forwardproxy/script/setup-gpg.sh
```

Then encrypt your **domain password** to the dedicated key (piped in, so it never
lands on disk; `printf` avoids a trailing newline):

```sh
GH=~/.config/forwardproxy/gnupg
printf '%s' 'DOMAIN_PASSWORD' | \
  gpg --homedir "$GH" -e -r 'forwardproxy (proxy secret) <forwardproxy@localhost>' \
      -o ~/.config/forwardproxy/secret.gpg
```

## 3. Configure office-only runtime settings

Home Manager installs the Quadlet file, dedicated gpg-agent unit, and the
office-only systemd drop-in from `config/`. It also installs
`environment.d/podman.conf`, setting `PODMAN` to the static podman path under
`${XDG_DATA_HOME:-$HOME/.local/share}/containers/bin/podman` for the user
manager/generator environment. Machine-specific values stay outside git in
`~/.config/forwardproxy/forwardproxy.env`.

On machines/networks where this proxy should run:

```sh
cp ~/.config/forwardproxy/forwardproxy.env.example ~/.config/forwardproxy/forwardproxy.env
$EDITOR ~/.config/forwardproxy/forwardproxy.env
```

Set at least `REALM`, `PRINCIPAL`, and `UPSTREAM_HOST`. The checked-in Quadlet
defaults to `BIND=127.0.0.1` and `PROXY_ACL=127.0.0.0/8`; widen those only when
containers or LAN clients must use the proxy.

The generated `forwardproxy.service` is skipped when
`~/.config/forwardproxy/forwardproxy.env` is absent, or when `UPSTREAM_HOST` does
not accept a TCP connection on `UPSTREAM_PORT` from the current network. This
mirrors the shell proxy check: the config can be installed everywhere, but it
only becomes active in the office environment.

Quadlet (`.container`) support needs **podman >= 4.4** (the systemd generator).

After `home-manager switch`:

```sh
systemctl --user start forwardproxy-gpg-agent.service forwardproxy.service
```

To survive reboot/logout without an interactive session:

```sh
systemctl --user enable forwardproxy-gpg-agent.service forwardproxy.service
loginctl enable-linger "$USER"   # start user services at boot, before login
```

No display is needed: the prompt is a terminal pinentry drawn inside a dedicated
tmux server (see below), so you don't import `DISPLAY` or run a GUI.

### Answering the pinentry prompt

Each ticket origination (≈ once a week, see [Renewal](#renewal--pinentry-frequency))
the agent must read your key passphrase. Because the agent is a daemon with no
terminal, a **dedicated tmux server** (its own socket, isolated from your normal
tmux) holds an idle pane that the prompt is drawn into. The agent's
`forwardproxy-gpg-agent.service` arms it at start — `ExecStartPost` runs
`pinentry-tmux arm`, which spawns the server and points the agent's tty at that
pane (`GPG_TTY` + `gpg-connect-agent updatestartuptty`) — so the pane exists as
soon as the agent is up, before any prompt. The `pinentry-tmux` pinentry-program
then draws curses pinentry there (re-arming the server first if it died). Attach
to answer it, any time:

```sh
tmux -S "${XDG_RUNTIME_DIR}/forwardproxy/pinentry.tmux.sock" attach
```

Type the passphrase, and the pane returns to idle (detach with `C-b d`). The
container's start blocks (up to `TimeoutStartSec=120`) until you do, so attach
soon after `systemctl --user start forwardproxy.service`. `journalctl --user -u
forwardproxy-gpg-agent` shows when a prompt is waiting.

## 4. Point everything at it (credential-less)

- **Host shell** — set `HTTP_PROXY=http://127.0.0.1:3128` (+ `HTTPS_PROXY`, keep
  `NO_PROXY`). This replaces the old `user:password@` URL entirely.
- **devenv** — `--env HTTP_PROXY=http://host.containers.internal:3128`
  (+ `HTTPS_PROXY`). No special network needed. If `host.containers.internal`
  doesn't resolve on your podman, add
  `--add-host=host.containers.internal:host-gateway`.
- **Image builds** — pass `HTTP_PROXY=http://127.0.0.1:3128` (or `--network host`)
  when a build needs the network; no credentials required.

After this, **no plaintext proxy credential exists anywhere on the host** — only
the gpg-encrypted `secret.gpg`.

## Renewal & pinentry frequency

One pinentry per ticket *origination*. After that the ticket renews silently
(`kinit -R`, no password) up to the realm's **renewable lifetime** (commonly
~7 days), so you get roughly **one prompt per week**. If the realm forbids
renewable tickets, the ticket can't be extended and you'll be prompted again each
time it expires (~10h) — that's a KDC policy you can't override, and it still
honors "secret only used to mint a token."

Squid re-reads the credential cache for each upstream authentication, so the
in-place `kinit -R` renewal is picked up automatically — no proxy restart and no
dropped connections at renewal time.

## ACL tuning

The tracked default is localhost-only. If containers need the proxy, widen
`BIND` and `PROXY_ACL` in `~/.config/forwardproxy/forwardproxy.env`, then watch
`journalctl --user -u forwardproxy` after first use and narrow the ACL to just
the networks you actually need.

## Troubleshooting

- `forwarded gpg-agent socket not found`: confirm the dedicated agent is up
  (`systemctl --user status forwardproxy-gpg-agent`) and that it created
  `${XDG_RUNTIME_DIR}/forwardproxy/S.gpg-agent.extra`.
- `decryption failed: No secret key`: confirm the dedicated keyring holds the key
  (`gpg --homedir ~/.config/forwardproxy/gnupg --list-secret-keys`) and that
  `secret.gpg` was encrypted to *that* key.
- pinentry never appears: it's drawn in the dedicated tmux server, not your
  terminal. Attach with `tmux -S "${XDG_RUNTIME_DIR}/forwardproxy/pinentry.tmux.sock"
  attach`. The socket is created when the agent starts (`ExecStartPost` →
  `pinentry-tmux arm`); if it's missing, check `journalctl --user -u
  forwardproxy-gpg-agent` for `pinentry-tmux: required program not found` (tmux /
  pinentry-curses / gpg-connect-agent not on the unit's `PATH`).
- `not a tty` / pinentry can't open the tty: restart
  `forwardproxy-gpg-agent.service` after updating. The unit clears
  `PINENTRY_USER_DATA` (so tmux/zellij popup routing isn't inherited) and sets
  `keep-tty`; the wrapper registers the dedicated pane's tty via
  `updatestartuptty`. Confirm the agent picked up `gpg-agent.conf`
  (`gpgconf --homedir ~/.config/forwardproxy/gnupg --reload gpg-agent`).
- `gpg: public key decryption failed: IPC syntax error`: old generated
  dedicated images may still be running an entrypoint that invokes decrypt with
  `--batch`, which prevents the expected host-side pinentry path. Rebuild the
  image and restart the service so decrypt runs with `--no-tty --pinentry-mode
  ask`. If it still fails, temporarily set `FORWARDPROXY_GPG_DEBUG=1` in
  `~/.config/forwardproxy/forwardproxy.env`, rebuild/restart, and inspect
  `journalctl --user -u forwardproxy` for the exact `gpg` status/debug lines.
- no container logs in `journalctl --user -u forwardproxy`: confirm the
  generated Quadlet unit includes `--log-driver=journald` after
  `systemctl --user daemon-reload`.
- `kinit` fails: check `REALM`/`PRINCIPAL`/`KDC` (or DNS SRV records for the
  realm), and that the password is correct. `klist` inside the container
  (`podman exec forwardproxy klist`) shows the current ticket.
- Upstream `407`/auth failures: confirm `UPSTREAM_HOST` is the proxy's FQDN so
  Squid requests the right service principal (`HTTP/UPSTREAM_HOST@REALM`), that a
  ticket exists (`podman exec forwardproxy klist`), and that this Squid was built
  with Kerberos/GSSAPI (`podman exec forwardproxy squid -v | grep -i negotiate`).
- Squid config rejected at start: the rendered file is checked with `squid -k
  parse` before launch; reproduce with `podman exec forwardproxy squid -k parse
  -f /run/squid.conf` and adjust `resource/squid.conf.template`. If upstream auth
  silently fails with `auth-no-keytab`, confirm the ticket cache is the type
  Squid's GSSAPI reads (the container forces `KRB5CCNAME=FILE:/run/krb5cc`).
