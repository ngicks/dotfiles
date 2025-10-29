import { injectRcFile, resourceNameFromShell } from "#/install/inject_rc.ts";
import { establishLink, linkPairs } from "#/install/symlink.ts";

async function main() {
  await establishLink(linkPairs);
  await injectRcFile(resourceNameFromShell(Deno.env.get("SHELL") ?? ""));
}

main();

