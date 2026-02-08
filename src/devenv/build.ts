export async function gitTag(): Promise<string> {
  const out = await (new Deno.Command(
    "git",
    {
      args: [
        "describe",
        "--tags",
        "--abbrev=0",
      ],
    },
  ).output());
  if (out.code != 0) {
    throw new Error(
      `git describe --tags --abbrev=0 failed: ${
        new TextDecoder().decode(out.stderr)
      }`,
    );
  }
  return new TextDecoder().decode(out.stdout).trim().slice(1);
}

export async function getTag(isExperimental: boolean): Promise<string> {
  let ver = await gitTag();

  if (isExperimental) {
    ver += "-exp1";
  }

  return ver;
}

export async function isAlreadyBuilt(ver: string) {
  const exist = await (new Deno.Command(
    "podman",
    {
      args: [
        "image",
        "inspect",
        `localhost/devenv/devenv:${ver}`,
      ],
    },
  ).output());
  return exist.code == 0;
}

export async function buildVer(ver: string, isExperimental: boolean) {
  const args = [
    "buildx",
    "build",
    ".",
    "--build-arg",
    `GIT_TAG=${isExperimental ? "exp" : ver}`,
    "-f",
    "./devenv/Containerfile",
    "-t",
    "localhost/devenv/devenv:" + ver,
    "--no-cache",
    ...(Deno.env.has("HTTP_PROXY")
      ? ["HTTP_PROXY", "HTTPS_PROXY", "NO_PROXY"]
        .map((v) => [v, v.toLowerCase()])
        .flat()
        .map((v) => [`--build-arg=${v}=${Deno.env.get(v) ?? ""}`]).flat()
      : []),
    `--secret`,
    `id=cert,src=${
      Deno.env.get("SSL_CERT_FILE") || "/etc/ssl/certs/ca-certificates.crt"
    }`,
  ];

  const cmd = new Deno.Command(
    "podman",
    {
      args,
      stdout: "piped",
      stderr: "piped",
    },
  );
  const s = cmd.spawn();
  await Promise.all([
    s.stdout.pipeTo(Deno.stdout.writable, { preventClose: true }),
    s.stderr.pipeTo(Deno.stderr.writable, { preventClose: true }),
  ]);
  const result = await s.status;
  if (!result.success) {
    throw new Error("build failed");
  }
}

export async function build(isExperimental: boolean) {
  const ver = await getTag(isExperimental);

  console.log(
    `building localhost/devenv/devenv:${ver}`,
  );

  if (await isAlreadyBuilt(ver)) {
    console.log("already built");
    return;
  }

  await buildVer(ver, isExperimental);
}
