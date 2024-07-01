import { type Application } from "types/service/applications";
import GLib from "gi://GLib?version=2.0";
import Gdk from "gi://Gdk";
import Gtk from "gi://Gtk?version=3.0";
import { icons } from "./icons";

/**
 * Clamps the given `value` between `min` and `max`.
 */
export const clamp = (value: number, min: number, max: number) => {
  return Math.min(Math.max(value, min), max);
};

/**
 * @returns `true` if all of the given `bins` are found.
 */
export const dependencies = (...bins: string[]) => {
  const missing = bins.filter((bin) =>
    Utils.exec({
      cmd: `which ${bin}`,
      out: () => false,
      err: () => true,
    })
  );

  if (missing.length > 0) {
    console.warn(Error(`Missing dependencies: ${missing.join(", ")}`));
    Utils.notify(`Missing dependencies: ${missing.join(", ")}`);
  }

  return missing.length === 0;
};

/**
 * @returns The given `widget` for each monitor.
 */
export const forMonitors = (widget: (monitor: number) => Gtk.Window) => {
  const n = Gdk.Display.get_default()?.get_n_monitors() || 1;

  return range(n, 0).flatMap(widget);
};

/**
 * Checks if an icon exists for the given `name`, or returns `fallback`.
 */
export const icon = (name: string | null, fallback = icons.missing) => {
  if (!name) return fallback || "";

  if (GLib.file_test(name, GLib.FileTest.EXISTS)) return name;

  const icon = name;
  if (Utils.lookUpIcon(icon)) return icon;

  print(`No icon found for "${name}", fallback: "${fallback}"`);
  return fallback;
};

/**
 * Run an app detached.
 */
export const launchApp = (app: Application) => {
  const exe = app.executable
    .split(/\s+/)
    .filter((str) => !str.startsWith("%") && !str.startsWith("@"))
    .join(" ");

  zsh(`${exe} &`);
  app.frequency += 1;
};

/**
 * @returns [start...length].
 */
export const range = (length: number, start = 1) => {
  return Array.from({ length }, (_, i) => i + start);
};

/**
 * @returns The result of `execAsync(cmd)`.
 */
export const sh = async (cmd: string | string[]) => {
  return Utils.execAsync(cmd).catch((error) => {
    console.error(typeof cmd === "string" ? cmd : cmd.join(" "), error);

    return "";
  });
};

/**
 * @returns The result of `execAsync(["zsh", "-c", cmd])`.
 */
export const zsh = async (cmds: TemplateStringsArray | string) => {
  const cmd = typeof cmds === "string" ? cmds : cmds.join(" ");

  return Utils.execAsync(["zsh", "-c", cmd]).catch((error) => {
    console.error(cmd, error);

    return "";
  });
};
