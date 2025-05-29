import path from "node:path";

const home =
  (Deno.build.os == "windows"
    ? Deno.env.get("USERPROFILE")
    : Deno.env.get("HOME")) ?? (() => {
      throw new Error("home dir not available");
    })();

export const config = {
  dir: {
    home,
    config: path.join(home, ".config"),
    cache: path.join(home, ".cache"),
    openjdkDir: path.join(home, ".local", "openjdk"),
  },
};
