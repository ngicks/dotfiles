import { gitPull } from "./git_pull.ts";
import { syncConfig } from "./sync_config.ts";

export const tasks = [
  {
    name: "git pull",
    task: gitPull,
  },
  {
    name: "sync config",
    task: syncConfig,
  },
];
