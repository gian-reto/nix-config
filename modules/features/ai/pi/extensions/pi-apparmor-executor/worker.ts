import type { Operation, SandboxRuntime } from "./executor.ts";
import {
  access,
  mkdir,
  readFile,
  readdir,
  stat,
  writeFile,
} from "node:fs/promises";
import { constants, createWriteStream } from "node:fs";
import { dirname, join } from "node:path";

import type { EditToolInput } from "@earendil-works/pi-coding-agent";
import { execFile } from "node:child_process";
import { finished } from "node:stream/promises";
import { promisify } from "node:util";

const controller = new AbortController();
process.once("SIGTERM", () => controller.abort());
process.once("SIGINT", () => controller.abort());

async function exists(path: string): Promise<boolean> {
  try {
    await access(path, constants.F_OK);
    return true;
  } catch (error) {
    if (
      error instanceof Error &&
      "code" in error &&
      ["ENOENT", "ENOTDIR"].includes(String(error.code))
    )
      return false;
    throw error;
  }
}

async function execute(
  request: Operation,
  runtime: SandboxRuntime,
): Promise<unknown> {
  switch (request.operation) {
    case "read":
      return (await readFile(request.path)).toString("base64");
    case "write":
      await writeFile(request.path, request.content);
      return null;
    case "access":
      await access(request.path, request.mode);
      return null;
    case "exists":
      return exists(request.path);
    case "stat":
      return (await stat(request.path)).isDirectory();
    case "readdir":
      return readdir(request.path);
    case "mkdir":
      await mkdir(request.path, { recursive: true });
      return null;
    case "glob": {
      const args = [
        "--glob",
        "--color=never",
        "--hidden",
        "--print0",
        "--max-results",
        String(request.limit),
      ];
      let root = request.cwd;
      while (!(await exists(join(root, ".git")))) {
        const parent = dirname(root);
        if (parent === root) {
          args.push("--no-require-git");
          break;
        }
        root = parent;
      }
      for (const exclude of request.ignore) args.push("--exclude", exclude);
      let pattern = request.pattern;
      if (pattern.includes("/")) {
        args.push("--full-path");
        if (!pattern.startsWith("/") && !pattern.startsWith("**/"))
          pattern = `**/${pattern}`;
      }
      const { stdout } = await promisify(execFile)(
        "fd",
        [...args, "--", pattern, request.cwd],
        {
          signal: controller.signal,
          maxBuffer: 64 * 1024 * 1024,
        },
      );
      return stdout.split("\0").filter(Boolean);
    }
    default: {
      const sdk: typeof import("@earendil-works/pi-coding-agent") =
        await import(runtime.sdk);
      if (request.operation === "mime")
        return (
          (await sdk.detectSupportedImageMimeTypeFromFile(request.path)) ?? null
        );
      if (request.operation === "preview") {
        // Reuse the edit algorithm without ever committing its proposed write.
        const tool = sdk.createEditTool(request.cwd, {
          operations: {
            readFile,
            access: (path) => access(path, constants.R_OK),
            writeFile: async () => {},
          },
        });
        const input =
          (await tool.prepareArguments?.(request.input)) ?? request.input;
        const result = await tool.execute(
          "preview",
          input as EditToolInput,
          controller.signal,
        );
        return result.details?.diff ?? "";
      }
      if (request.operation === "shell") {
        const stream = createWriteStream("", { fd: 3, autoClose: false });
        try {
          const operations =
            request.shell === "powershell"
              ? sdk.createLocalPowerShellOperations()
              : sdk.createLocalBashOperations({ shellPath: request.shellPath });
          return await operations.exec(request.command, request.cwd, {
            env: request.env,
            timeout: request.timeout,
            signal: controller.signal,
            onData: (data) => {
              stream.write(data);
            },
          });
        } finally {
          stream.end();
          await finished(stream);
        }
      }
      throw new Error("Unknown sandbox operation");
    }
  }
}

try {
  let input = "";
  process.stdin.setEncoding("utf8");
  for await (const chunk of process.stdin) input += chunk;
  const request = JSON.parse(input) as Operation & { runtime: SandboxRuntime };
  const { runtime } = request;
  const label = (
    await readFile("/proc/self/attr/apparmor/current", "utf8")
  ).trim();
  if (label !== `${runtime.profileName} (enforce)`)
    throw new Error(
      `Sandbox operations require the ${runtime.profileName} AppArmor profile in enforce mode`,
    );
  process.stdout.write(
    JSON.stringify({ result: await execute(request, runtime) }),
  );
} catch (error) {
  process.stdout.write(
    JSON.stringify({
      error: {
        message: error instanceof Error ? error.message : String(error),
        code:
          error instanceof Error && "code" in error ? error.code : undefined,
      },
    }),
  );
  process.exitCode = 1;
}
