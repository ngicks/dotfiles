const buf = await Deno.readTextFile(Deno.args[0]);

const lines = buf
  .split("\n")
  .flatMap((l) => {
    if (l.startsWith("ExecStart") || l.startsWith("ExecStop")) {
      l = l.replaceAll("podman", Deno.args[2]);
    }
    if (l.startsWith("ExecStart=")) {
      // prepend line
      return [`EnvironmentFile=${Deno.args[1]}`, l];
    }
    return l;
  });

await Deno.writeTextFile(Deno.args[0], lines.join("\n"));
