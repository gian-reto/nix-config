import {
  renderDiff,
  type createEditToolDefinition,
  type EditToolDetails,
  type ToolDefinition,
} from "@earendil-works/pi-coding-agent";
import { Box, Spacer, Text } from "@earendil-works/pi-tui";
import type { Sandbox } from "./executor.ts";

interface PreviewState {
  key?: string;
  requested?: boolean;
  pending?: boolean;
  completed?: boolean;
  controller?: AbortController;
  diff?: string;
  error?: string;
}

type EditDefinition = ReturnType<typeof createEditToolDefinition>;

export function withConfinedPreview(
  definition: EditDefinition,
  sandbox: Sandbox,
) {
  return {
    ...definition,
    renderCall(args, theme, ctx) {
      const state = ctx.state;
      const path =
        args.path ??
        ("file_path" in args && typeof args.file_path === "string"
          ? args.file_path
          : undefined);
      const key = JSON.stringify(args);
      if (state.key !== key) {
        state.controller?.abort();
        Object.assign(state, {
          key,
          requested: false,
          pending: false,
          completed: false,
          controller: undefined,
          diff: undefined,
          error: undefined,
        });
      }
      if (
        ctx.argsComplete &&
        typeof path === "string" &&
        !state.requested &&
        !state.completed
      ) {
        state.requested = true;
        state.pending = true;
        state.controller = new AbortController();
        void sandbox
          .call<string>(
            { operation: "preview", input: args, cwd: ctx.cwd },
            state.controller.signal,
          )
          .then(
            (diff) => {
              if (state.key === key && !state.completed) state.diff = diff;
            },
            (error: unknown) => {
              if (state.key === key && !state.completed)
                state.error =
                  error instanceof Error ? error.message : String(error);
            },
          )
          .finally(() => {
            if (state.key === key) state.pending = false;
            ctx.invalidate();
          });
      }
      const box =
        ctx.lastComponent instanceof Box
          ? ctx.lastComponent
          : new Box(ctx.outputPad, 1);
      box.setBgFn((text) =>
        theme.bg(
          state.error
            ? "toolErrorBg"
            : state.completed || state.diff !== undefined
              ? "toolSuccessBg"
              : "toolPendingBg",
          text,
        ),
      );
      box.clear();
      box.addChild(
        new Text(
          `${theme.fg("toolTitle", theme.bold("edit"))} ${theme.fg("accent", path ?? "...")}`,
          0,
          0,
        ),
      );
      if (state.diff || state.error || (state.pending && !state.completed)) {
        box.addChild(new Spacer(1));
        box.addChild(
          new Text(
            state.error
              ? theme.fg("error", state.error)
              : state.diff
                ? renderDiff(state.diff, { filePath: path })
                : theme.fg("muted", "Computing diff…"),
            0,
            0,
          ),
        );
      }
      return box;
    },
    renderResult(result, options, _theme, ctx) {
      if (!options.isPartial) {
        const diff = ctx.isError ? undefined : result.details?.diff;
        const error = ctx.isError
          ? result.content
              .filter((part) => part.type === "text")
              .map((part) => part.text)
              .join("\n")
          : undefined;
        if (
          !ctx.state.completed ||
          ctx.state.diff !== diff ||
          ctx.state.error !== error
        ) {
          Object.assign(ctx.state, { completed: true, diff, error });
          ctx.state.controller?.abort();
          ctx.invalidate();
        }
      }
      return new Text("", 0, 0);
    },
  } satisfies ToolDefinition<
    EditDefinition["parameters"],
    EditToolDetails | undefined,
    PreviewState
  >;
}
