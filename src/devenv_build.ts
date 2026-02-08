import { build } from "#/devenv/build.ts";

async function main() {
  const exp = Deno.args.includes("--exp") || Deno.args.includes("-e");
  await build(exp);
}

main();
