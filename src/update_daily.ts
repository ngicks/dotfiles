import process from "node:process";

import { markerFilePath } from "#/daily/config.ts";
import { doDaily } from "#/daily/do_daily.ts";
import { tasks } from "#/daily/tasks.ts";

async function main() {
  const force = Deno.args.includes("--force") || Deno.args.includes("-f");
  const { done, next } = await doDaily(tasks, { force });
  process.stderr.write(
    `update ${done ? "done" : "deferred"}
If you want update happened again immediately, remove ${markerFilePath}

next update occurrs after ${next}
`,
  );
}

await main();
