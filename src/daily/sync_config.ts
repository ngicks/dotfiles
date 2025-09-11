import path from "node:path";
import fs from "node:fs";

const syncPairs = [
  {
    name: "wezterm",
    target: ".config/wezterm",
  },
];

async function isWsl(): Promise<boolean> {
  try {
    for await (const dirent of Deno.readDir("/proc/sys/fs/binfmt_misc")) {
      if (dirent.name.startsWith("WSLInterop")) {
        return true;
      }
    }
    return false;
  } catch (err) {
    if (!(err instanceof Deno.errors.NotFound)) {
      throw err;
    }
    return false;
  }
}

async function needsSync(): Promise<boolean> {
  if (Deno.build.os !== "linux") {
    return false;
  }
  return await isWsl();
}

export async function getHostProfileDir(): Promise<string> {
  const cmd = new Deno.Command("powershell.exe", {
    args: [`$env:USERPROFILE`],
  });
  const output = await cmd.output();
  if (output.code !== 0) {
    throw new Error(
      `powershell.exe failed. stderr: ${
        new TextDecoder().decode(output.stderr)
      }`,
    );
  }
  const out = new TextDecoder().decode(output.stdout);
  const driveLetter = out.split(":")[0];
  const path = out.substring(driveLetter.length + 1).trimEnd();
  return "/mnt/" + driveLetter.toLowerCase() + path.replaceAll("\\", "/");
}

export async function syncConfig(): Promise<void> {
  if (!(await needsSync())) {
    return;
  }

  const hostProfileDir = await getHostProfileDir();

  for (const pair of syncPairs) {
    const src = path.join("./.config", pair.name);
    const dst = path.join(hostProfileDir, pair.target);

    console.log(`src = ${src}, dst = ${dst}`);

    await Deno.mkdir(dst, { recursive: true });

    for await (const dirent of Deno.readDir(src)) {
      await fs.promises.cp(
        path.join(src, dirent.name),
        dst,
        { recursive: true, force: true },
      );
    }
  }
}
