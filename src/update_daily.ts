import { markerFilePath } from "#/daily/config.ts";
import { doDaily } from "#/daily/do_daily.ts";
import { tasks } from "#/daily/tasks.ts";

async function main() {
  const force = Deno.args.includes("--force") || Deno.args.includes("-f");
  const { done, next } = await doDaily(tasks, { force });
  Deno.stderr.write(
    new TextEncoder().encode(
      `update ${done ? "done" : "deferred"}
If you want update to happen again immediately, remove ${markerFilePath}

next update occurrs after ${next}
`,
    ),
  );
}

await main();
