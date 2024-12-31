import { Gdk, Gtk } from "astal/gtk4";

import { Gio } from "astal";
import { isPathOfValidImage } from "./path";

/**
 * Looks up an icon by name and size.
 *
 * This function retrieves an icon from the default icon theme based on the
 * provided name, scale, and size. If the name is not provided, it returns
 * `undefined`.
 *
 * @param name The name of the icon to look up.
 * @param scale The scale of the icon to look up.
 * @param size The size of the icon to look up. Defaults to `64`.
 *
 * @returns The {@link Gtk.IconPaintable} object if the icon is found, or null
 * if not found.
 */
export const lookUpIcon = (
  name: string,
  scale: number,
  size = 64,
  fallbackIconName: string = "image-missing-symbolic"
): Gtk.IconPaintable | undefined => {
  if (!name) return undefined;
  const display = Gdk.Display.get_default();
  if (!display) return undefined;

  return Gtk.IconTheme.get_for_display(display).lookup_icon(
    name,
    [fallbackIconName, "image-missing-symbolic"],
    size,
    scale,
    Gtk.TextDirection.NONE,
    null
  );
};

/**
 * Returns the icon belonging to the given `nameOrPath` as a
 * {@link Gtk.IconPaintable} if it is a valid icon name, or a {@link Gio.File}
 * if it is a valid image path. Otherwise, it will return the fallback icon, or
 * `undefined` if the icon is not found or another error occurs.
 */
export const getIconFromNameOrPath = (
  nameOrPath: string,
  window: Gtk.Window,
  size: number,
  fallbackIconName: string = "image-missing-symbolic"
):
  | {
      readonly type: "none";
    }
  | {
      readonly type: "file";
      readonly path: string;
    }
  | {
      readonly type: "paintable";
      readonly paintable: Gtk.IconPaintable;
    } => {
  const icon = nameOrPath || fallbackIconName;

  if (isPathOfValidImage(icon)) {
    const path = Gio.File.new_for_path(icon).get_path();
    if (!path) {
      return {
        type: "none",
      };
    }

    return {
      type: "file",
      path,
    };
  }

  const paintable = lookUpIcon(
    icon,
    window.get_scale_factor(),
    size,
    fallbackIconName
  );
  if (paintable) {
    return {
      type: "paintable",
      paintable,
    };
  }

  return {
    type: "none",
  };
};
