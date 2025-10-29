import path from "node:path";

import { basePaths } from "#/lib/config.ts";

export interface LinkPair {
  src: string;
  dst: string;
}

export const linkPairs: LinkPair[] = [
  {
    src: "./.config",
    dst: basePaths.config,
  },
];

export async function establishLink(pairs: LinkPair[]) {
  for (const pair of pairs) {
    for await (const dirent of Deno.readDir(pair.src)) {
      const src = path.join(pair.src, dirent.name);
      const dst = path.join(pair.dst, dirent.name);
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
}
