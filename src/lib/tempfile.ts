export class TemporaryFile {
  path: string;
  f: Deno.FsFile;
  constructor(path: string, f: Deno.FsFile) {
    this.path = path;
    this.f = f;
  }

  static async create(path: string): Promise<TemporaryFile> {
    return new TemporaryFile(path, await Deno.create(path));
  }

  static async open(
    path: string,
    option?: Deno.OpenOptions,
  ): Promise<TemporaryFile> {
    return new TemporaryFile(path, await Deno.open(path, option));
  }

  [Symbol.asyncDispose]() {
    try {
      this.f[Symbol.dispose]();
    } catch {
      // ignore error
    }
    return Deno.remove(this.path);
  }
}
