import path from "node:path";

import { config } from "#/config.ts";
import { scanDir } from "#/jdk/scan_dir.ts";

class TemporaryFile {
  path: string;
  f: Deno.FsFile;
  constructor(path: string, f: Deno.FsFile) {
    this.path = path;
    this.f = f;
  }

  static async create(path: string): Promise<TemporaryFile> {
    return new TemporaryFile(path, await Deno.create(path));
  }

  static async open(
    path: string,
    option?: Deno.OpenOptions,
  ): Promise<TemporaryFile> {
    return new TemporaryFile(path, await Deno.open(path, option));
  }

  [Symbol.asyncDispose]() {
    try {
      this.f[Symbol.dispose]();
    } catch {
      // ignore error
    }
    return Deno.remove(this.path);
  }
}

export const urls = {
  24:
    "https://download.java.net/java/GA/jdk24/1f9ff9062db4449d8ca828c504ffae90/36/GPL/openjdk-24_${os}-${arch}_bin.${ext}",
  23:
    "https://download.java.net/java/GA/jdk23.0.2/6da2a6609d6e406f85c491fcb119101b/7/GPL/openjdk-23.0.2_${os}-${arch}_bin.${ext}",
  22:
    "https://download.java.net/java/GA/jdk22.0.2/c9ecb94cd31b495da20a27d4581645e8/9/GPL/openjdk-22.0.2_${os}-${arch}_bin.${ext}",
  21:
    "https://download.java.net/java/GA/jdk21.0.2/f2283984656d49d69e91c558476027ac/13/GPL/openjdk-21.0.2_${os}-${arch}_bin.${ext}",
  20:
    "https://download.java.net/java/GA/jdk20.0.2/6e380f22cbe7469fa75fb448bd903d8e/9/GPL/openjdk-20.0.2_${os}-${arch}_bin.${ext}",
  19:
    "https://download.java.net/java/GA/jdk19.0.1/afdd2e245b014143b62ccb916125e3ce/10/GPL/openjdk-19.0.1_${os}-${arch}_bin.${ext}",
  18:
    "https://download.java.net/java/GA/jdk18.0.2/f6ad4b4450fd4d298113270ec84f30ee/9/GPL/openjdk-18.0.2_${os}-${arch}_bin.${ext}",
  17:
    "https://download.java.net/java/GA/jdk17.0.2/dfd4a8d0985749f896bed50d7138ee7f/8/GPL/openjdk-17.0.2_${os}-${arch}_bin.${ext}",
  16:
    "https://download.java.net/java/GA/jdk16.0.2/d4a915d82b4c4fbb9bde534da945d746/7/GPL/openjdk-16.0.2_${os}-${arch}_bin.${ext}",
  15:
    "https://download.java.net/java/GA/jdk15.0.2/0d1cfde4252546c6931946de8db48ee2/7/GPL/openjdk-15.0.2_${os}-${arch}_bin.${ext}",
  14:
    "https://download.java.net/java/GA/jdk14.0.2/205943a0976c4ed48cb16f1043c5c647/12/GPL/openjdk-14.0.2_${os}-${arch}_bin.${ext}",
  13:
    "https://download.java.net/java/GA/jdk13.0.2/d4173c853231432d94f001e99d882ca7/8/GPL/openjdk-13.0.2_${os}-${arch}_bin.${ext}",
  12:
    "https://download.java.net/java/GA/jdk12.0.2/e482c34c86bd4bf8b56c0b35558996b9/10/GPL/openjdk-12.0.2_${os}-${arch}_bin.${ext}",
  11:
    "https://download.java.net/java/GA/jdk11/9/GPL/openjdk-11.0.2_${os}-${arch}_bin.${ext}",
  10:
    "https://download.java.net/java/GA/jdk10/10.0.2/19aef61b38124481863b1413dce1855f/13/openjdk-10.0.2_${os}-${arch}_bin.${ext}",
  9: "https://download.java.net/java/GA/jdk9/9.0.4/binaries/openjdk-9.0.4_${os}-${arch}_bin.${ext}",
};

export async function install() {
  const { os, arch } = Deno.build;

  let tempDir = "";

  await Deno.mkdir(config.dir.openjdkDir, { recursive: true });

  const installedVersions = await scanDir();

  console.log(`already has installed:`, installedVersions);

  LOOP:
  for (const [version, baseUrl] of Object.entries(urls)) {
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
          args: ["-xf", dest, "-C", config.dir.openjdkDir],
        },
      );
      await cmd.output();
    }
  }
}
