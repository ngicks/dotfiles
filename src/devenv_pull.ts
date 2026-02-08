import { pull } from "#/devenv/pull.ts";

async function main() {
  const remote = Deno.args.find((a) => !a.startsWith("-"));
  if (!remote) {
    throw new Error("usage: devenv:pull <remote> [--exp] [--no-build]");
  }
  const exp = Deno.args.includes("--exp") || Deno.args.includes("-e");
  const noBuild = Deno.args.includes("--no-build");
  await pull(remote, noBuild, exp);
}

main();
