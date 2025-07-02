import path from "node:path";

import { config } from "#/config.ts";

async function main(args: string[]) {
  if (args.length == 0) {
    throw new Error("specify path for podman config dir.");
  }

  const podmanConfigPath = args[0];

  const containersPath = path.join(podmanConfigPath, "containers.conf");
  const containers = await Deno.readTextFile(
    containersPath,
  );
  await Deno.writeTextFile(
    containersPath,
    containers.split("\n").map((l) => {
      if (!l.startsWith("helper_binaries_dir")) {
        return l;
      }
      return l.replaceAll("$HOME", config.dir.home);
    }).join("\n"),
  );

  const storagesPath = path.join(podmanConfigPath, "storage.conf");
  const storages = await Deno.readTextFile(
    storagesPath,
  );
  await Deno.writeTextFile(
    storagesPath,
    storages.split("\n").map((l) => {
      if (!l.startsWith("mount_program")) {
        return l;
      }
      return l.replaceAll("$HOME", config.dir.home);
    }).join("\n"),
  );
}

main(Deno.args);
