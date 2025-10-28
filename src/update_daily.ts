import { markerFilePath, noAutoUpdateMarkerFilePath } from "#/daily/config.ts";
import { doDaily } from "#/daily/do_daily.ts";
import { tasks } from "#/daily/tasks.ts";

async function main() {
  const force = Deno.args.includes("--force") || Deno.args.includes("-f");
  const { done, stopped, next } = await doDaily(tasks, { force });

  let message = "";
  if (!stopped) {
    message =
      `If you want update to happen again immediately, remove ${markerFilePath}

next update occurrs after ${next}`;
  } else {
    message = `no auto update marker found.

If you want daily-update to happen again,
remove ${noAutoUpdateMarkerFilePath}
or put either of -f or --force option`;
  }

  Deno.stderr.write(
    new TextEncoder().encode(
      `update ${done ? "done" : "deferred"}

${message}
`,
    ),
  );
}

await main();
