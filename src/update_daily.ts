import { mergeReadableStreams } from "jsr:@std/streams";

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
      break;
    case (s instanceof Error):
      throw s;
    case ((current.getTime() -
      ((<Deno.FileInfo> s).mtime?.getTime() ?? 0)) <=
      minimumInterval):
      await Deno.stderr.write(
        new TextEncoder().encode(
          `next update occurrs after ${new Date(
            ((<Deno.FileInfo> s).mtime?.getTime() ?? 0) + minimumInterval,
          )}
`,
        ),
      );
      return;
  }

  const cmd = new Deno.Command("git", {
    args: ["pull", "--recurse-submodules"],
    stdout: "piped",
    stderr: "piped",
  }).spawn();
  const merged = mergeReadableStreams(cmd.stdout, cmd.stderr);
  await merged.pipeTo(Deno.stderr.writable);
  await cmd.status;
  await Deno.open(timestampFilePath, { create: true, write: true });
  await Deno.utime(timestampFilePath, current, current);
}

await main();
