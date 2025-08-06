import path from "node:path";

import { interval, markerFilePath } from "./config.ts";

export async function doDaily(
  tasks: { name: string; task: () => Promise<void> }[],
): Promise<{ done: boolean; next: Date }> {
  await Deno.mkdir(path.dirname(markerFilePath), { recursive: true });

  const s = await Deno.stat(markerFilePath).catch((e: Error) => e);

  const current = new Date();
  switch (true) {
    case (s instanceof Deno.errors.NotFound):
      break;
    case (s instanceof Error):
      throw s;
    case ((current.getTime() -
      ((<Deno.FileInfo> s).mtime?.getTime() ?? 0)) <=
      interval):
      return {
        done: false,
        next: new Date(((<Deno.FileInfo> s).mtime?.getTime() ?? 0) + interval),
      };
  }

  const errs: { name: string; err: Error }[] = [];
  for (const task of tasks) {
    try {
      await task.task();
    } catch (err) {
      if (err instanceof Error) {
        errs.push({ name: task.name, err });
      } else {
        const newErr = new Error(`task ${task.name} failed`);
        newErr.cause = err;
        errs.push({ name: task.name, err: newErr });
      }
    }
  }

  if ((errs.length) > 0) {
    const err = new Error("task failed");
    err.cause = errs;
    throw err;
  }

  await Deno.open(markerFilePath, { create: true, write: true });
  await Deno.utime(markerFilePath, current, current);

  return { done: true, next: new Date(current.getTime() + interval) };
}
