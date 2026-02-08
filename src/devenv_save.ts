import { save } from "#/devenv/save.ts";

async function main() {
  const exp = Deno.args.includes("--exp") || Deno.args.includes("-e");
  const noBuild = Deno.args.includes("--no-build");
  await save(noBuild, exp);
}

main();
