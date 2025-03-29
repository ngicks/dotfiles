import path from "node:path";

import { config } from "#/config.ts";

const dirs = ["./.config"];

for (const dir of dirs) {
  for await (const dirent of Deno.readDir(dir)) {
    await Deno.symlink(
      path.relative(
        config.dir.config,
        path.join(dir, dirent.name),
      ),
      path.join(config.dir.config, dirent.name),
    );
  }
}

const markerCommentStart = "# MYDOTFILE INJECTION START\n";
const markerCommentEnd = "# MYDOTFILE INJECTION END\n";
function buildInjectedScriptLines(conf: typeof config): string {
  const relativeConfDir = path.relative(conf.dir.home, conf.dir.config);
  return `
if [ -d ./${relativeConfDir}/env ]; then
  for f in ./${relativeConfDir}/env/*.env; do
    set -a            
    . $f
    set +a
  done

  for f in ./${relativeConfDir}/env/*.sh; do 
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
