import { AsyncLocalStorage } from "node:async_hooks";
import type { BashOperations } from "@earendil-works/pi-coding-agent";
import { spawn } from "node:child_process";

export interface SandboxRuntime {
  profileName: string;
  sdk: string;
  worker: string;
}

export type Operation =
  | {
      operation: "read" | "mime" | "readdir" | "stat" | "exists" | "mkdir";
      path: string;
    }
  | { operation: "access"; path: string; mode: number }
  | { operation: "write"; path: string; content: string }
  | {
      operation: "glob";
      pattern: string;
      cwd: string;
      ignore: string[];
      limit: number;
    }
  | { operation: "preview"; input: unknown; cwd: string }
  | {
      operation: "shell";
      command: string;
      cwd: string;
      shell: "bash" | "powershell";
      shellPath?: string;
      timeout?: number;
      env?: NodeJS.ProcessEnv;
    };

type Reply =
  { result: unknown } | { error: { message: string; code?: string } };

export function createSandbox(getRuntime: () => SandboxRuntime) {
  let runtime: SandboxRuntime | undefined;
  const signals = new AsyncLocalStorage<AbortSignal | undefined>();
  function call<T>(
    request: Operation,
    signal: AbortSignal | undefined = signals.getStore(),
    onData?: (data: Buffer) => void,
  ): Promise<T> {
    if (signal?.aborted) return Promise.reject(new Error("Operation aborted"));
    return new Promise((resolve, reject) => {
      runtime ??= getRuntime();
      const child = spawn(
        "aa-exec",
        ["-p", runtime.profileName, "--", "node", runtime.worker],
        {
          detached: true,
          stdio: ["pipe", "pipe", "pipe", "pipe"],
        },
      );
      let output = "";
      let stderr = "";
      let failure: Error | undefined;
      let timer: ReturnType<typeof setTimeout> | undefined;
      const kill = (signal: NodeJS.Signals) => {
        if (child.pid) {
          try {
            process.kill(-child.pid, signal);
          } catch (error) {
            if (!(
              error instanceof Error &&
              "code" in error &&
              error.code === "ESRCH"
            )) {
              failure ??=
                error instanceof Error ? error : new Error(String(error));
            }
          }
        }
      };
      const abort = () => {
        kill("SIGTERM");
        timer ??= setTimeout(() => kill("SIGKILL"), 1500);
        timer.unref();
      };
      signal?.addEventListener("abort", abort, { once: true });
      child.stdout.setEncoding("utf8").on("data", (data: string) => {
        output += data;
      });
      child.stderr.setEncoding("utf8").on("data", (data: string) => {
        stderr = (stderr + data).slice(-8192);
      });
      child.stdio[3]?.on("data", (data: Buffer) => onData?.(data));
      child.stdin.on("error", (error: Error) => {
        failure ??= error;
      });
      child.on("error", (error) => {
        failure ??= error;
      });
      child.on("close", (code) => {
        signal?.removeEventListener("abort", abort);
        if (timer) clearTimeout(timer);
        if (signal?.aborted) return reject(new Error("Operation aborted"));
        if (failure) return reject(failure);
        try {
          const reply = JSON.parse(output) as Reply;
          if ("error" in reply) {
            const denied =
              reply.error.code === "EACCES" || reply.error.code === "EPERM";
            const message = denied
              ? "Access to a resource was denied by an AppArmor profile. " +
                "The operation is prohibited by a policy and should not be reattempted. " +
                "Either ask the user to provide more information, or continue your task using an alternative strategy without accessing the requested resource." +
                `\n\nOriginal error: ${reply.error.message}`
              : reply.error.message;
            return reject(
              Object.assign(new Error(message), {
                code: reply.error.code,
              }),
            );
          }
          if (code !== 0 || !("result" in reply))
            throw new Error("Missing sandbox result");
          resolve(reply.result as T);
        } catch {
          reject(
            new Error(
              `AppArmor execution failed: ${stderr.trim() || `worker exited with status ${code}`}. Ensure the configured profile is loaded in enforce mode and the required commands are available.`,
            ),
          );
        }
      });
      child.stdin.end(JSON.stringify({ ...request, runtime }));
      if (signal?.aborted) abort();
    });
  }

  const shell = (
    name: "bash" | "powershell",
    shellPath?: string,
  ): BashOperations => ({
    exec: (command, cwd, options) =>
      call<{ exitCode: number | null }>(
        {
          operation: "shell",
          shell: name,
          shellPath,
          command,
          cwd,
          env: options.env,
          timeout: options.timeout,
        },
        options.signal,
        options.onData,
      ),
  });
  const readFile = async (path: string): Promise<Buffer> =>
    Buffer.from(await call<string>({ operation: "read", path }), "base64");
  return {
    call,
    shell,
    readFile,
    withSignal: <T>(signal: AbortSignal | undefined, action: () => T): T =>
      signals.run(signal, action),
    writeFile: (path: string, content: string) =>
      call<void>({ operation: "write", path, content }),
    access: (path: string, mode: number) =>
      call<void>({ operation: "access", path, mode }),
    exists: (path: string) => call<boolean>({ operation: "exists", path }),
    stat: async (path: string) => {
      const directory = await call<boolean>({ operation: "stat", path });
      return { isDirectory: () => directory };
    },
  };
}

export type Sandbox = ReturnType<typeof createSandbox>;
