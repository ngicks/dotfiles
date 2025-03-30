import { scanDir } from "#/jdk/scan_dir.ts";

export async function dotenv(): Promise<string> {
  const vers = await scanDir();

  const sorted = Object.entries(vers).map(([k, v]) => [Number(k), v]).sort((
    i,
    j,
  ) => i[0] === j[0] ? 0 : i[0] > j[0] ? +1 : -1);

  // maybe we'll need shell escape.
  return sorted.map(([ver, path]) => `JAVA${ver}_HOME=${path}`).join(
    "\n",
  );
}
