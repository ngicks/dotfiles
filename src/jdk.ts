import { dotenv } from "#/jdk/dotenv.ts";
import { install } from "#/jdk/install.ts";

const subCommand = Deno.args[0];

const commands = {
  install: install,
  dotenv: async () => {
    console.log(await dotenv());
  },
};

if (!Object.hasOwn(commands, subCommand)) {
  throw new Error(
    `unknown command ${subCommand}. possible commands = [${
      Object.keys(commands)
    }]`,
  );
}

//@ts-ignore checked above.
await commands[subCommand]();
