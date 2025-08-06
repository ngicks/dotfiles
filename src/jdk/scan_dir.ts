import path from "node:path";

import { openJdkBasePath } from "./config.ts";

export async function scanDir() {
  const versions: Record<number, string> = {};
  for await (const dirent of Deno.readDir(openJdkBasePath)) {
    if (!dirent.isDirectory || !dirent.name.startsWith("jdk-")) {
      continue;
    }

    const ver = Number(dirent.name.slice("jdk-".length).split(".")?.[0]);
    if (Number.isNaN(ver)) {
      continue;
    }

    versions[ver] = path.join(openJdkBasePath, dirent.name);
  }
  return versions;
}
