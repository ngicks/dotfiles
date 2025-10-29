import path from "node:path";

import { BasePaths, basePaths } from "#/lib/config.ts";
import { denoRootDir } from "#/lib/root.ts";

export interface RcPair {
  shell: string;
  rc: string;
}

export const rcPairs: Map<string, RcPair> = new Map(
  [
    [
      "bash",
      { shell: "bash", rc: ".bashrc" },
    ],
    [
      "zsh",
      { shell: "zsh", rc: ".zshrc" },
    ],
  ],
);

export const markerCommentStart = "# MYDOTFILE INJECTION START\n";
export const markerCommentEnd = "# MYDOTFILE INJECTION END\n";

export function resourceNameFromShell(shell: string): string {
  if (!rcPairs.has(path.basename(shell))) {
    throw new Error(`unknown shell: ${shell}`);
  }
  return rcPairs.get(path.basename(shell))!.rc;
}

export async function injectRcFile(rcPath: string) {
  const filename = path.join(basePaths.home, path.basename(rcPath));
  try {
    const content = await Deno.readTextFile(filename);
    let before = content;
    let after = "";

    if (content.indexOf(markerCommentStart) >= 0) {
      const startOff = content.indexOf(markerCommentStart);
      let endOff = content.lastIndexOf(markerCommentEnd);
      if (endOff >= 0) {
        endOff += markerCommentEnd.length;
      } else {
        endOff = content.length;
      }
      before = content.substring(0, startOff);
      after = content.substring(endOff);
    }

    await Deno.writeTextFile(
      filename,
      before +
        `${markerCommentStart}
${await buildInjectedScriptLines(basePaths)}
${markerCommentEnd}` + after,
    );
  } catch (err) {
    if (!(err instanceof Deno.errors.NotFound)) {
      throw err;
    }
  }
}

export async function buildInjectedScriptLines(
  basePaths: BasePaths,
): Promise<string> {
  const rootDir = await denoRootDir(new URL(import.meta.url).pathname);
  const relativeDotEnvDir = path.relative(basePaths.home, rootDir);

  let relativeConfDir = path.relative(basePaths.home, basePaths.config);
  if (relativeConfDir.startsWith("./")) {
    relativeConfDir = relativeConfDir.substring("./".length);
  }

  return buildInjectedScriptLines_(relativeConfDir, relativeDotEnvDir);
}

function buildInjectedScriptLines_(
  relativeConfDir: string,
  relativeDotEnvDir: string,
): string {
  return `if [[ -d "$HOME/${relativeConfDir}/dotfiles_init" ]]; then
  for f in $HOME/${relativeConfDir}/dotfiles_init/*.sh; do
    . $f
  done
fi

if [[ -d "$HOME/${relativeConfDir}/env" ]]; then
  if ls $HOME/${relativeConfDir}/env/ | grep -e '.*\\.env' > /dev/null 2>&1; then
    for f in $HOME/${relativeConfDir}/env/*.env; do
      set -a
      . $f
      set +a
    done
  fi

  if ls $HOME/${relativeConfDir}/env/ | grep -e '.*\\.sh' > /dev/null 2>&1; then
    for f in $HOME/${relativeConfDir}/env/*.sh; do
      . $f
    done
  fi
fi

# Run daily update check
if command -v dotfiles_should_update >/dev/null 2>&1; then
  if dotfiles_should_update; then
    pushd $HOME/${relativeDotEnvDir} > /dev/null
    deno task update:daily > /dev/null
    popd > /dev/null
  else
    echo "update deferred"
    echo "If you want update to happen again immediately, remove $HOME/.cache/dotfiles/.update_daily"
    echo ""
    echo "next update occurrs after $(dotfiles_next_update_time)"
  fi
else
  # Fallback if function not defined
  pushd $HOME/${relativeDotEnvDir} > /dev/null
  deno task update:daily > /dev/null
  popd > /dev/null
fi
`;
}
