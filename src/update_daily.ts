import path from "node:path";

import { config } from "#/config.ts";

const timestampFilePath = path.join(
  config.dir.cache,
  "dotfiles",
  ".update_daily",
);

const minimumInterval = 16 * 60 * 60 * 1000;

async function main() {
  await Deno.mkdir(path.dirname(timestampFilePath), { recursive: true });

  const s = await Deno.stat(timestampFilePath).catch((e: Error) => e);
  const current = new Date();
  switch (true) {
    case (s instanceof Deno.errors.NotFound):
      await Deno.open(timestampFilePath, { create: true, write: true });
      break;
    case (s instanceof Error):
      throw s;
    case ((current.getTime() -
      ((<Deno.FileInfo> s).mtime?.getTime() ?? 0)) <=
      minimumInterval):
      console.log(
        `next update occurrs after ${new Date(
          ((<Deno.FileInfo> s).mtime?.getTime() ?? 0) + minimumInterval,
        )}`,
      );
      return;
  }

  const out = await new Deno.Command("git", {
    args: ["pull", "--recurse-submodules"],
  }).output();
  console.log(new TextDecoder().decode(out.stdout));
  await Deno.utime(timestampFilePath, current, current);
}

await main();
