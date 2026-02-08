# Remote Devenv Image Save & Pull

## Context

The devenv system builds containerized dev environments using `podman buildx build`. Currently the workflow is local-only. The user wants to:
1. Build images on a remote node via SSH, save as gzipped tar
2. Pull saved images to local and load into local podman

This eliminates the need to SSH manually into build nodes and enables portable image distribution.

## Files to Modify

- `src/devenv/save.ts` - Rewrite: remote SSH build + save logic
- `src/devenv/pull.ts` - **New**: pull from remote + load into local podman
- `src/devenv_save.ts` - **New**: entry point for `devenv:save` task
- `src/devenv_pull.ts` - **New**: entry point for `devenv:pull` task
- `deno.json` - Add tasks and permission scopes

## Existing Code to Reuse

- `src/devenv/build.ts` - `getTag()`, `gitTag()` for tag resolution
- `src/lib/config.ts` - `basePaths.cache` for local cache directory
- Stream piping pattern from `buildVer()` in `build.ts:70-86`
- Entry point pattern from `devenv_build.ts`

## Design

### Image naming convention
- File: `devenv-${tag}.tar.gz` (e.g. `devenv-1.2.3.tar.gz`, `devenv-1.2.3-exp1.tar.gz`)
- Image: `localhost/devenv/devenv:${tag}`
- Remote path: `~/.cache/dotfiles/devenv/image/devenv-${tag}.tar.gz`
- Local path: `${basePaths.cache}/dotfiles/devenv/image/devenv-${tag}.tar.gz`

### Remote node configuration
- `DEVENV_REMOTE` env var (format: `user@host` or `host`)
- Relies on user's SSH agent / `~/.ssh/config` for auth
- Remote must have: `deno`, `podman` (with buildx), `git`, `gzip`

### SSH execution helper
- Reusable `sshExec(remote, script)` function using `Deno.Command("ssh", ...)` with stream piping (same pattern as `buildVer`)
- All remote scripts use `set -euo pipefail` for robustness

### Experimental build handling
- `gitTag()` returns the base version (e.g. `1.2.3`)
- `getTag(true)` appends `-exp1` → `1.2.3-exp1` (used for image tag only)
- Remote checkout uses `gitTag()` (base tag without `-exp1`) since `-exp1` is not a real git tag
- Remote build passes `--exp` flag to `deno task devenv:build` which sets `GIT_TAG=exp` in Containerfile

## Implementation Steps

### 1. Rewrite `src/devenv/save.ts`

Replace the current stub. The module will export:
- `imageFileName(tag)` - returns `devenv-${tag}.tar.gz`
- `remoteCachePath(fileName)` - returns `~/.cache/dotfiles/devenv/image/${fileName}`
- `getRemote()` - reads `DEVENV_REMOTE` env, throws if unset
- `sshExec(remote, script)` - runs bash script over SSH with stream piping
- `save(noBuild, isExperimental)` - orchestrates:
  1. Get `baseTag` via `gitTag()` and `imageTag` via `getTag()`
  2. Get remote via `getRemote()`
  3. SSH to remote with `set -euo pipefail`:
     - Clone dotfiles repo to `~/.cache/dotfiles/devenv/repo` if not present (or fetch updates)
     - `git -C ... fetch --tags && git -C ... checkout v${baseTag}`
     - `cd repo && deno task devenv:build` (add `--exp` if experimental)
     - `mkdir -p ~/.cache/dotfiles/devenv/image`
     - `podman save ${imageName} | gzip > ${remotePath}`
  4. If `noBuild`: skip build, only check image exists on remote then save

### 2. Create `src/devenv/pull.ts`

Exports `pull(isExperimental)`:
1. Get tag, remote, compute local/remote paths
2. `Deno.mkdir` local cache dir (recursive)
3. `scp remote:path localPath` - transfer the gzipped image
4. Pipe `gzip -dc localPath` into `podman load` using Deno stream piping (use `gzip -dc` instead of `gunzip` for portability)
5. Log success

### 3. Create `src/devenv_save.ts`

Entry point matching `devenv_build.ts` pattern:
- Parse `--exp`/`-e` and `--no-build` flags
- Call `save(noBuild, exp)`

### 4. Create `src/devenv_pull.ts`

Entry point:
- Parse `--exp`/`-e` flag
- Call `pull(exp)`

### 5. Update `deno.json`

Add tasks:
```json
"devenv:save": "deno run -P=devenv:save src/devenv_save.ts",
"devenv:pull": "deno run -P=devenv:pull src/devenv_pull.ts"
```

Add permission scopes:
```json
"devenv:save": {
  "run": ["git", "ssh"],
  "env": ["DEVENV_REMOTE", "HTTP_PROXY", "HTTPS_PROXY", "http_proxy", "https_proxy", "NO_PROXY", "no_proxy", "SSL_CERT_FILE"]
},
"devenv:pull": {
  "read": true,
  "write": true,
  "run": ["git", "scp", "gzip", "podman"],
  "env": ["DEVENV_REMOTE", "HOME", "XDG_CACHE_HOME"]
}
```

## Verification

1. `deno check src/devenv_save.ts` and `deno check src/devenv_pull.ts` - type check
2. `deno task devenv:save --exp` with `DEVENV_REMOTE` set - test remote build+save
3. `deno task devenv:pull --exp` with `DEVENV_REMOTE` set - test pull+load
4. Verify image loaded: `podman image inspect localhost/devenv/devenv:${tag}`
