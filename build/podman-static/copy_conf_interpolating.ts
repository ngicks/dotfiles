import path from "node:path";

async function main(args: string[]) {
  if (args.length != 4) {
    throw new Error("specify path for podman config dir.");
  }

  const [confSrcDir, podmanConfigPath, targetHome, targetXdgDataHome] = args;

  for await (const dirent of Deno.readDir(confSrcDir)) {
    if (!dirent.isFile) {
      throw new Error(
        `confSrcDir contains non-regular file: ${
          path.join(confSrcDir, dirent.name)
        }`,
      );
    }
    const srcText = await Deno.readTextFile(path.join(confSrcDir, dirent.name));
    await Deno.writeTextFile(
      path.join(podmanConfigPath, dirent.name),
      srcText
        .replaceAll(
          "${HOME}",
          targetHome,
        )
        .replaceAll(
          "${XDG_DATA_HOME}",
          targetXdgDataHome,
        ),
    );
  }
}

main(Deno.args);
