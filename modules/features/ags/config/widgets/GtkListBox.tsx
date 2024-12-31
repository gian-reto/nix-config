import { ConstructProps, Gtk, astalify } from "astal/gtk4";

import { cx } from "../util/cx";
import { ensureWidgetArray } from "../util/widget";

export type GtkListBoxProps = Omit<_GtkListBoxProps, "cssClasses"> & {
  readonly cssClasses?: string[];
};

export const GtkListBox = (props: GtkListBoxProps) => {
  const { cssClasses, ...restProps } = props;

  return (
    <_GtkListBox {...restProps} cssClasses={cx(cssClasses, "gtk-list-box")} />
  );
};

type _GtkListBoxProps = ConstructProps<
  Gtk.ListBox,
  Gtk.ListBox.ConstructorProps
>;

const _GtkListBox = astalify<Gtk.ListBox, Gtk.ListBox.ConstructorProps>(
  Gtk.ListBox,
  {
    getChildren: (self) => {
      const rows: Array<Gtk.ListBoxRow> = [];
      for (let index = 0; self.get_row_at_index(index) !== null; index++) {
        rows.push(self.get_row_at_index(index)!);
      }

      return rows;
    },
    setChildren(self, children) {
      const currentChildren = this.getChildren?.(self);
      for (const child of currentChildren || []) {
        self.remove(child);
      }
      for (const child of ensureWidgetArray(children)) {
        self.append(child);
      }
    },
  }
);
