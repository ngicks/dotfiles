export interface BasePaths {
  home: string;
  config: string;
  cache: string;
}

function onWindows(): BasePaths {
  return {
    home: Deno.env.get("USERPROFILE")!,
    config: Deno.env.get("AppData")!,
    cache: Deno.env.get("LocalAppData")!,
  };
}

function onDarwin(): BasePaths {
  const home = Deno.env.get("HOME")!;
  return {
    home,
    config: home + "/Library/Application Support",
    cache: home + "/Library/Caches",
  };
}

function onUnix(): BasePaths {
  const home = Deno.env.get("HOME")!;
  return {
    home,
    config: Deno.env.get("XDG_CONFIG_HOME") ??
      home + "/.config",
    cache: Deno.env.get("XDG_CACHE_HOME") ??
      home + "/.cache",
  };
}

function validateBasePath(paths: BasePaths): BasePaths {
  Object.entries(paths).forEach(([k, v]) => {
    if (typeof v !== "string") {
      throw new Error(`${k} is not defined`);
    }
  });
  return paths;
}

export const basePaths = validateBasePath((() => {
  switch (Deno.build.os) {
    default:
      throw new Error(`unsupported os: ${Deno.build.os}`);
    case "linux":
      return onUnix();
    case "darwin":
      return onDarwin();
    case "windows":
      return onWindows();
  }
})());
