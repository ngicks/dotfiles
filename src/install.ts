import path from "node:path";

import { BasePaths, basePaths } from "#/lib/config.ts";
import { denoRootDir } from "#/lib/root.ts";

const dirs = ["./.config"];

for (const dir of dirs) {
  for await (const dirent of Deno.readDir(dir)) {
    const src = path.join(dir, dirent.name);
    const dst = path.join(basePaths.config, dirent.name);
    try {
      await Deno.symlink(
        path.relative(
          basePaths.config,
          src,
        ),
        dst,
      );
    } catch (err) {
      if (!(err instanceof Deno.errors.AlreadyExists)) {
        throw err;
      }
      const s = await Deno.lstat(dst);
      if (s.isSymlink) {
        console.log(`skipped linking: ${dst}`);
      } else {
        console.warn(`not a link: ${dst}`);
      }
    }
  }
}

const markerCommentStart = "# MYDOTFILE INJECTION START\n";
const markerCommentEnd = "# MYDOTFILE INJECTION END\n";
async function buildInjectedScriptLines(basePaths: BasePaths): Promise<string> {
  const rootDir = await denoRootDir(new URL(import.meta.url).pathname);
  const relativeDotEnvDir = path.relative(basePaths.home, rootDir);

  let relativeConfDir = path.relative(basePaths.home, basePaths.config);
  if (relativeConfDir.startsWith("./")) {
    relativeConfDir = relativeConfDir.substring("./".length);
  }
  return `if [[ -d "$HOME/${relativeConfDir}/initial_path" ]]; then
  for f in $HOME/${relativeConfDir}/initial_path/*.sh; do
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
  fi
else
  # Fallback if function not defined
  pushd $HOME/${relativeDotEnvDir} > /dev/null
  deno task update:daily > /dev/null
  popd > /dev/null
fi
`;
}

for (const rcFile of [".bashrc", ".zshrc"]) {
  const filename = path.join(basePaths.home, rcFile);
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
