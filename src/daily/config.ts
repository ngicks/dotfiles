import path from "node:path";

import { basePaths } from "#/lib/config.ts";

export const interval = 16 * 60 * 60 * 1000;

export const markerFilePath = path.join(
  basePaths.cache,
  "dotfiles",
  ".update_daily",
);

export const noAutoUpdateMarkerFilePath = path.join(
  basePaths.cache,
  "dotfiles",
  ".no_update_daily",
);
