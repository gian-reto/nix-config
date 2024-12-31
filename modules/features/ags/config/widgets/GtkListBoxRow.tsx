import { ConstructProps, Gtk, astalify } from "astal/gtk4";

import { cx } from "../util/cx";

export type GtkListBoxRowProps = Omit<_GtkListBoxRowProps, "cssClasses"> & {
  readonly cssClasses?: string[];
};

export const GtkListBoxRow = (props: GtkListBoxRowProps) => {
  const { cssClasses, ...restProps } = props;

  return (
    <_GtkListBoxRow
      {...restProps}
      cssClasses={cx(cssClasses, "gtk-list-box-row")}
    />
  );
};

type _GtkListBoxRowProps = ConstructProps<
  Gtk.ListBoxRow,
  Gtk.ListBoxRow.ConstructorProps
>;

const _GtkListBoxRow = astalify<
  Gtk.ListBoxRow,
  Gtk.ListBoxRow.ConstructorProps
>(Gtk.ListBoxRow);
