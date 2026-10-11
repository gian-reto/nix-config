import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

function requestId(data: unknown): string | undefined {
  if (
    typeof data !== "object" ||
    data === null ||
    Array.isArray(data) ||
    !("requestId" in data)
  ) {
    return undefined;
  }

  const id = data.requestId;
  return typeof id === "string" && id.trim().length > 0 ? id : undefined;
}

export default function (pi: ExtensionAPI) {
  if (
    process.env.HERDR_ENV !== "1" ||
    !process.env.HERDR_SOCKET_PATH ||
    !process.env.HERDR_PANE_ID
  ) {
    return;
  }

  const pending = new Set<string>();
  let visibleSession = false;

  function emitBlocked(active: boolean): void {
    try {
      pi.events.emit(
        "herdr:blocked",
        active ? { active, label: "Permission Required" } : { active },
      );
    } catch {
      // Observational failures must not interfere with permission enforcement.
    }
  }

  const stopPrompts = pi.events.on("permissions:ui_prompt", (data) => {
    const id = requestId(data);
    if (!visibleSession || id === undefined || pending.has(id)) {
      return;
    }

    const alreadyBlocked = pending.size > 0;
    pending.add(id);
    if (!alreadyBlocked) {
      emitBlocked(true);
    }
  });

  const stopDecisions = pi.events.on("permissions:decision", (data) => {
    const id = requestId(data);
    if (id === undefined || !pending.delete(id) || pending.size > 0) {
      return;
    }
    emitBlocked(false);
  });

  pi.on("session_start", (_event, ctx) => {
    // Match Herdr's TUI gate: Forwarded prompts block their visible host only.
    visibleSession = ctx.mode === "tui";
  });

  pi.on("session_shutdown", () => {
    visibleSession = false;
    if (pending.size > 0) {
      pending.clear();
      emitBlocked(false);
    }
    stopPrompts();
    stopDecisions();
    // Pi replaces both adapters after shutdown on reload or session switching.
  });
}
