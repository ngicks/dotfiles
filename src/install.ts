import path from "node:path";

import { config } from "#/config.ts";

const dirs = ["./.config"];

for (const dir of dirs) {
  for await (const dirent of Deno.readDir(dir)) {
    const src = path.join(dir, dirent.name);
    const dst = path.join(config.dir.config, dirent.name);
    try {
      await Deno.symlink(
        path.relative(
          config.dir.config,
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
function buildInjectedScriptLines(conf: typeof config): string {
  let relativeConfDir = path.relative(conf.dir.home, conf.dir.config);
  if (relativeConfDir.startsWith("./")) {
    relativeConfDir = relativeConfDir.substring("./".length);
  }
  return `if [[ -d "$HOME/${relativeConfDir}/env" ]]; then
  for f in $HOME/${relativeConfDir}/env/*.env; do
    set -a            
    . $f
    set +a
  done

  for f in $HOME/${relativeConfDir}/env/*.sh; do
    . $f
  done
fi
`;
}

for (const rcFile of [".bashrc"]) {
  const filename = path.join(config.dir.home, rcFile);
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
${buildInjectedScriptLines(config)}
${markerCommentEnd}` + after,
    );
  } catch (err) {
    if (!(err instanceof Deno.errors.NotFound)) {
      throw err;
    }
  }
}
