import path from "node:path";

export async function denoRootDir(startPoint: string): Promise<string> {
  return await rootDir(startPoint, [
    "deno.json",
    "deno.jsonc",
    "package.json",
    ".git",
  ]);
}

export async function rootDir(
  startPoint: string,
  markers: string[],
): Promise<string> {
  if (markers.length === 0) {
    throw new Error("empty markers");
  }

  let current = path.resolve(startPoint);
  const s = await Deno.stat(current);
  if (!s.isDirectory) {
    current = path.dirname(current);
  }

  while (current !== path.dirname(current)) {
    for await (const dirent of Deno.readDir(current)) {
      if (markers.includes(dirent.name)) {
        return current;
      }
    }
    current = path.dirname(current);
  }
  throw new Error("root not found");
}
