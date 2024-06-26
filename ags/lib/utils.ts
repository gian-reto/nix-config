import Gdk from "gi://Gdk";
import Gtk from "gi://Gtk?version=3.0";

/**
 * Clamps the given `value` between `min` and `max`.
 */
export const clamp = (value: number, min: number, max: number) => {
  return Math.min(Math.max(value, min), max);
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
  return Utils.execAsync(cmd).catch((err) => {
    console.error(typeof cmd === "string" ? cmd : cmd.join(" "), err);

    return "";
  });
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
