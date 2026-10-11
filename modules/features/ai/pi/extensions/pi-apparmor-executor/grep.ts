import { homedir } from "node:os";
import { basename, relative, resolve } from "node:path";
import { StringDecoder } from "node:string_decoder";
import {
  createGrepToolDefinition,
  DEFAULT_MAX_BYTES,
  formatSize,
  truncateHead,
  truncateLine,
  type GrepToolDetails,
} from "@earendil-works/pi-coding-agent";
import type { Sandbox } from "./executor.ts";

export function createConfinedGrep(cwd: string, sandbox: Sandbox) {
  return {
    ...createGrepToolDefinition(cwd),
    async execute(_id, input, signal, _update, ctx) {
      if (signal?.aborted) throw new Error("Operation aborted");
      const path = input.path ?? ".";
      const searchPath = resolve(
        ctx.cwd,
        path === "~" ? homedir() : path.replace(/^~\//, `${homedir()}/`),
      );
      const directory = (await sandbox.stat(searchPath)).isDirectory();
      const limit = Math.max(1, input.limit ?? 100);
      const context = Math.max(0, input.context ?? 0);
      const args = [
        "rg",
        "--json",
        "--line-number",
        "--color=never",
        "--hidden",
      ];
      if (input.ignoreCase) args.push("--ignore-case");
      if (input.literal) args.push("--fixed-strings");
      if (input.glob) args.push("--glob", input.glob);
      args.push("--", input.pattern, searchPath);
      const command = args
        .map((arg) => `'${arg.replaceAll("'", `'"'"'`)}'`)
        .join(" ");
      const matches: { path: string; line: number; text: string }[] = [];
      const stop = new AbortController();
      const combined = signal
        ? AbortSignal.any([signal, stop.signal])
        : stop.signal;
      const decoder = new StringDecoder("utf8");
      let pending = "";
      let stderr = "";
      const consume = (line: string) => {
        if (!line.trim() || matches.length >= limit) return;
        try {
          const event = JSON.parse(line) as {
            type?: string;
            data?: {
              path?: { text?: string };
              line_number?: number;
              lines?: { text?: string };
            };
          };
          if (
            event.type === "match" &&
            typeof event.data?.path?.text === "string" &&
            typeof event.data.line_number === "number"
          ) {
            matches.push({
              path: event.data.path.text,
              line: event.data.line_number,
              text: event.data.lines?.text ?? "",
            });
            if (matches.length >= limit) stop.abort();
          }
        } catch {
          stderr = (stderr + line + "\n").slice(-8192);
        }
      };
      try {
        const result = await sandbox.shell("bash").exec(command, ctx.cwd, {
          signal: combined,
          onData: (data) => {
            pending += decoder.write(data);
            let end: number;
            while ((end = pending.indexOf("\n")) !== -1) {
              consume(pending.slice(0, end));
              pending = pending.slice(end + 1);
            }
          },
        });
        consume(pending + decoder.end());
        if (result.exitCode !== 0 && result.exitCode !== 1)
          throw new Error(
            stderr.trim() || `ripgrep exited with code ${result.exitCode}`,
          );
      } catch (error) {
        if (!stop.signal.aborted || signal?.aborted) throw error;
      }
      if (signal?.aborted) throw new Error("Operation aborted");
      if (!matches.length)
        return {
          content: [{ type: "text" as const, text: "No matches found" }],
          details: undefined,
        };

      const files = new Map<string, string[]>();
      const output: string[] = [];
      const details: GrepToolDetails = {};
      const append = (
        path: string,
        line: number,
        text: string,
        match: boolean,
      ) => {
        const short = directory ? relative(searchPath, path) : basename(path);
        const truncated = truncateLine(text.replace(/\r/g, ""));
        if (truncated.wasTruncated) details.linesTruncated = true;
        output.push(
          `${short}${match ? ":" : "-"}${line}${match ? ": " : "- "}${truncated.text}`,
        );
      };
      for (const match of matches) {
        if (signal?.aborted) throw new Error("Operation aborted");
        if (!context) {
          append(match.path, match.line, match.text.replace(/\n$/, ""), true);
          continue;
        }
        if (!files.has(match.path)) {
          try {
            files.set(
              match.path,
              (await sandbox.readFile(match.path))
                .toString("utf8")
                .replace(/\r\n?/g, "\n")
                .split("\n"),
            );
          } catch {
            files.set(match.path, []);
          }
        }
        const lines = files.get(match.path)!;
        if (!lines.length) {
          append(match.path, match.line, "(unable to read file)", true);
          continue;
        }
        for (
          let line = Math.max(1, match.line - context);
          line <= Math.min(lines.length, match.line + context);
          line++
        ) {
          append(match.path, line, lines[line - 1] ?? "", line === match.line);
        }
      }
      const truncation = truncateHead(output.join("\n"), {
        maxLines: Number.MAX_SAFE_INTEGER,
      });
      const notices: string[] = [];
      if (matches.length >= limit) {
        details.matchLimitReached = limit;
        notices.push(
          `${limit} matches limit reached. Use limit=${limit * 2} for more, or refine pattern`,
        );
      }
      if (truncation.truncated) {
        details.truncation = truncation;
        notices.push(`${formatSize(DEFAULT_MAX_BYTES)} limit reached`);
      }
      if (details.linesTruncated)
        notices.push(
          `Some lines truncated to 500 chars. Use read tool to see full lines`,
        );
      return {
        content: [
          {
            type: "text" as const,
            text:
              truncation.content +
              (notices.length ? `\n\n[${notices.join(". ")}]` : ""),
          },
        ],
        details: Object.keys(details).length ? details : undefined,
      };
    },
  } satisfies ReturnType<typeof createGrepToolDefinition>;
}
