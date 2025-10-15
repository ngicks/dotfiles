const verFile = "devenv_ver";

function incrementVer(ver: string): string {
  const [v1, v2, v3] = ver.split(".");
  return [v1, v2, String(Number(v3) + 1)].join(".");
}

async function main() {
  const bump = Deno.args.includes("--bump") || Deno.args.includes("-b");
  const currentVer = (await Deno.readTextFile(verFile)).trim();

  const ver = (() => {
    if (!bump) {
      return currentVer;
    }
    return incrementVer(currentVer);
  })();

  console.log(`building devenv:${ver}`);

  if (!bump) {
    const exist = await (new Deno.Command(
      "podman",
      {
        args: [
          "image",
          "inspect",
          `devenv:${ver}`,
        ],
      },
    ).output());
    if (exist.code == 0) {
      console.log("ready build");
      return;
    }
  }

  const cmd = new Deno.Command(
    "podman",
    {
      args: [
        "buildx",
        "build",
        ".",
        "-f",
        "./devenv.Dockerfile",
        "-t",
        "devenv:" + ver,
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
  if (!(await s.status).success) {
    throw new Error("build failed");
  }
  await Deno.writeTextFile(verFile, ver);
}

main();
