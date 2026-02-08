import path from "node:path";

import { build, getTag } from "#/devenv/build.ts";
import { basePaths } from "#/lib/config.ts";

export function cacheDirPath(): string {
  return path.join(basePaths.cache, "dotfiles", "devenv", "image");
}

export function imageFileName(tag: string): string {
  return `localhost_devenv_devenv-${tag}.tar.gz`;
}

export async function save(noBuild: boolean, isExperimental: boolean) {
  const tag = await getTag(isExperimental);
  const imageName = `localhost/devenv/devenv:${tag}`;

  if (!noBuild) {
    await build(isExperimental);
  } else {
    console.log(`skipping build, saving existing image ${imageName}`);
  }

  const dir = cacheDirPath();
  await Deno.mkdir(dir, { recursive: true });
  const filePath = path.join(dir, imageFileName(tag));

  try {
    await Deno.stat(filePath);
    console.log(`already saved: ${filePath}`);
    return;
  } catch (e) {
    if (!(e instanceof Deno.errors.NotFound)) throw e;
  }

  console.log(`saving ${imageName} to ${filePath}`);

  const tmpPath = filePath + ".tmp";

  const podman = new Deno.Command("podman", {
    args: ["save", imageName],
    stdout: "piped",
    stderr: "piped",
  });
  const podmanProc = podman.spawn();

  const gzip = new Deno.Command("gzip", {
    stdin: "piped",
    stdout: "piped",
    stderr: "piped",
  });
  const gzipProc = gzip.spawn();

  const outFile = await Deno.open(tmpPath, {
    write: true,
    create: true,
    truncate: true,
  });

  await Promise.all([
    podmanProc.stdout.pipeTo(gzipProc.stdin),
    podmanProc.stderr.pipeTo(Deno.stderr.writable, { preventClose: true }),
    gzipProc.stdout.pipeTo(outFile.writable),
    gzipProc.stderr.pipeTo(Deno.stderr.writable, { preventClose: true }),
  ]);

  const [podmanResult, gzipResult] = await Promise.all([
    podmanProc.status,
    gzipProc.status,
  ]);
  if (!podmanResult.success) {
    throw new Error("podman save failed");
  }
  if (!gzipResult.success) {
    throw new Error("gzip failed");
  }

  await Deno.rename(tmpPath, filePath);
  console.log(`saved ${filePath}`);
}
