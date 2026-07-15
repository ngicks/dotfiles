# Port To MoonBit

Backlog notes for moving dotfiles maintenance scripts toward MoonBit native
binaries. The goal is faster startup where it matters, better portability, and
less fragile shell orchestration.

## Main Targets

1. Deno-based management code
   - Target `src/` and any `deno task update:*` flow.
   - Highest likely payoff because Deno startup is much heavier than shell or a
     native helper.
   - Especially important for anything called from login, install, upgrade, or
     daily update paths.

2. `scripts/homeenv/*`
   - Good target for structured file edits, config generation, version checks,
     and command orchestration.
   - Prioritize scripts that run many external commands or are used by
     `homeenv-install.sh` / `homeenv-upgrade.sh`.

3. `build/*`
   - Target `build/krun/*` and `builder/podman-static-dist/*`.
   - This is less about shell startup speed and more about maintainability,
     OS/arch branching, argument handling, and testability.

4. Generated login shell bundle
   - Keep `config/loginscript/*` split for editing.
   - Generate one or two shell files for startup, for example zshenv and zshrc
     bundles.
   - This should be done before replacing login snippets with a native env
     emitter, because it preserves shell semantics and avoids child-process
     overhead.

5. Repeated prompt/status helpers
   - Consider `config/tmux/set_status_*.sh` and any prompt/status helper that
     runs repeatedly.
   - Repeated hooks can matter more than one-time login snippets.

## Lower Priority

- Tiny `export` snippets in `config/loginscript/env/*.sh`.
- Shell hook definitions that need to mutate the current zsh process.
- Completion setup and terminal integration code that is naturally shell code.
- Neovim Lua config.
- One-off installer wrappers unless they become hard to maintain.

## Notes

- A MoonBit binary cannot directly mutate the parent shell environment. If it is
  used for login setup, it must emit shell code and be consumed with `eval`.
- `eval "$(binary)"` can help when it replaces many external commands or heavy
  runtimes, but it may be slower than sourcing shell for simple exports.
- Combining split shell snippets into generated shell is simpler and likely the
  first thing to benchmark.
- Measure before and after. Likely bottlenecks include `mise activate`, `curl`
  proxy checks on cache miss, Deno update tasks, and cache-miss prompt data
  generation.
