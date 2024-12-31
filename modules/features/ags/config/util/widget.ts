import { Gtk } from "astal/gtk4";

/**
 * Ensures that the given array contains only {@link Gtk.Widget} instances,
 * collapsing the array if it's nested and converting any invalid items to a
 * {@link Gtk.Label} with the string representation of the original value.
 */
export const ensureWidgetArray = (
  array: any[]
): Array<Gtk.Widget | Gtk.Label> => {
  return array
    .flat(Infinity)
    .map((item) =>
      item instanceof Gtk.Widget
        ? item
        : new Gtk.Label({ visible: true, label: String(item) })
    );
};
