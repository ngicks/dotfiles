import { getTag } from "#/devenv/build.ts";
import { cacheDirPath, imageFileName } from "#/devenv/save.ts";

async function sshExec(remote: string, command: string) {
  const cmd = new Deno.Command("ssh", {
    args: [remote, command],
    stdout: "piped",
    stderr: "piped",
  });
  const proc = cmd.spawn();
  await Promise.all([
    proc.stdout.pipeTo(Deno.stdout.writable, { preventClose: true }),
    proc.stderr.pipeTo(Deno.stderr.writable, { preventClose: true }),
  ]);
  const result = await proc.status;
  if (!result.success) {
    throw new Error(`ssh command failed: ${command}`);
  }
}

async function scpExec(remote: string, remotePath: string, localPath: string) {
  const cmd = new Deno.Command("scp", {
    args: [`${remote}:${remotePath}`, localPath],
    stdout: "piped",
    stderr: "piped",
  });
  const proc = cmd.spawn();
  await Promise.all([
    proc.stdout.pipeTo(Deno.stdout.writable, { preventClose: true }),
    proc.stderr.pipeTo(Deno.stderr.writable, { preventClose: true }),
  ]);
  const result = await proc.status;
  if (!result.success) {
    throw new Error("scp failed");
  }
}

export async function pull(
  remote: string,
  noBuild: boolean,
  isExperimental: boolean,
) {
  const tag = await getTag(isExperimental);
  const fileName = imageFileName(tag);
  const localDir = cacheDirPath();
  const localPath = `${localDir}/${fileName}`;
  const imageName = `localhost/devenv/devenv:${tag}`;

  // 1. SSH to remote and run devenv:save
  const flags = [
    isExperimental ? "--exp" : "",
    noBuild ? "--no-build" : "",
  ].filter(Boolean).join(" ");

  console.log(`running devenv:save on ${remote}`);
  await sshExec(
    remote,
    `. ~/.zshrc && cd ~/.dotfiles && deno task devenv:save${
      flags ? " " + flags : ""
    }`,
  );

  // 2. SCP the saved image (skip if already cached)
  const remoteCachePath = `~/.cache/dotfiles/devenv/image/${fileName}`;
  await Deno.mkdir(localDir, { recursive: true });

  let cached = false;
  try {
    await Deno.stat(localPath);
    cached = true;
  } catch (e) {
    if (!(e instanceof Deno.errors.NotFound)) throw e;
  }

  if (cached) {
    console.log(`already cached: ${localPath}`);
  } else {
    const tmpPath = localPath + ".tmp";
    console.log(`pulling ${fileName} from ${remote}`);
    await scpExec(remote, remoteCachePath, tmpPath);
    await Deno.rename(tmpPath, localPath);
  }

  // 3. Load into local podman (handles gzip natively)
  console.log(`loading ${fileName} into podman`);

  const podman = new Deno.Command("podman", {
    args: ["load", "-i", localPath],
    stdout: "piped",
    stderr: "piped",
  });
  const podmanProc = podman.spawn();

  await Promise.all([
    podmanProc.stdout.pipeTo(Deno.stdout.writable, { preventClose: true }),
    podmanProc.stderr.pipeTo(Deno.stderr.writable, { preventClose: true }),
  ]);

  const podmanResult = await podmanProc.status;
  if (!podmanResult.success) {
    throw new Error("podman load failed");
  }

  console.log(`loaded ${imageName}`);
}
