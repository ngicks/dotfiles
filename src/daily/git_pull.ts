import { mergeReadableStreams } from "jsr:@std/streams";

export async function gitPull() {
  const cmd = new Deno.Command("git", {
    args: ["pull"],
    stdout: "piped",
    stderr: "piped",
  }).spawn();
  const merged = mergeReadableStreams(cmd.stdout, cmd.stderr);
  await merged.pipeTo(Deno.stderr.writable, { preventClose: true });
  await cmd.status;
}
