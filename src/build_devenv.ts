const verFile = "devenv_ver";

function incrementVer(ver: string): string {
  const [v1, v2, v3] = ver.split(".");
  return [v1, v2, String(Number(v3) + 1)].join(".");
}

async function main() {
  const ver = (await Deno.readTextFile(verFile)).trim();
  const newVer = incrementVer(ver);
  console.log(`next version: ${newVer}`);
  const cmd = new Deno.Command(
    "podman",
    {
      args: [
        "image",
        "build",
        ".",
        "-f",
        "./devenv.Dockerfile",
        "-t",
        "devenv:" + newVer,
        "--no-cache",
      ],
      stdout: "piped",
      stderr: "piped",
    },
  );
  const s = cmd.spawn();
  await s.stdout.pipeTo(Deno.stdout.writable, { preventClose: true });
  await s.stderr.pipeTo(Deno.stderr.writable, { preventClose: true });
  await s.output();
  await Deno.writeTextFile(verFile, newVer);
}

main();
