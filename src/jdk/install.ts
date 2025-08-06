import path from "node:path";

import { TemporaryFile } from "#/lib/tempfile.ts";

import { scanDir } from "./scan_dir.ts";
import { openJdkBasePath, openJdkUrls } from "./config.ts";

export async function install() {
  const { os, arch } = Deno.build;

  let tempDir = "";

  await Deno.mkdir(openJdkBasePath, { recursive: true });

  const installedVersions = await scanDir();

  console.log(`already has installed:`, installedVersions);

  LOOP:
  for (const [version, baseUrl] of Object.entries(openJdkUrls)) {
    if (Object.hasOwn(installedVersions, Number(version))) {
      console.log(`skipping ${version}: installed`);
      continue LOOP;
    }

    const osReplacer: string = (() => {
      switch (os) {
        case "darwin":
          if (Number(version) < 17) {
            return "osx";
          } else {
            return "macos";
          }
        case "windows":
          return os;
        case "linux":
          return os;
        default:
          throw new Error("os not supported: " + os);
      }
    })();
    const archReplacer: string = (() => {
      switch (arch) {
        case "x86_64":
          return "x64";
        case "aarch64":
          return arch;
      }
    })();

    const extReplacer = (() => {
      if (os == "windows") {
        return "zip";
      }
      return "tar.gz";
    })();

    if (arch == "aarch64") {
      switch (os) {
        case "windows":
          throw new Error("windows aarch64 is not supported");
        case "linux":
          if (Number(version) < 15) {
            console.log(`skipping version ${version}: arch not supported`);
            continue LOOP;
          }
          break;
        case "darwin":
          if (Number(version) < 17) {
            console.log(`skipping version ${version}: arch not supported`);
            continue LOOP;
          }
          break;
      }
    }

    if (tempDir == "") {
      tempDir = await Deno.makeTempDir();
    }
    const targetUrl = new URL(
      baseUrl.replace("${os}", osReplacer).replace(
        "${arch}",
        archReplacer,
      ).replace("${ext}", extReplacer),
    );

    const filename = targetUrl.pathname.split("/").at(-1) as string;
    console.log(
      `downloading ${targetUrl} to ${tempDir}/${filename}`,
    );
    {
      const dest = path.join(tempDir, filename);
      await using f = await TemporaryFile.create(dest);

      const resp = await fetch(targetUrl);
      if (!resp.ok) {
        throw new Error("download failed with " + await resp.text());
      }

      await resp.body?.pipeTo(f.f.writable);

      console.log(`extracting...`);
      const cmd = new Deno.Command(
        // seemingly on windows,
        // The `tar` command accepts .zip file.
        // Maybe that's why they have decided to bundle bsdtar rather than GNU.
        "tar",
        {
          args: ["-xf", dest, "-C", openJdkBasePath],
        },
      );
      await cmd.output();
    }
  }
}
