import { ConstructProps, Gtk, astalify } from "astal/gtk4";

import { cx } from "../util/cx";

export type GtkSeparatorProps = Omit<_GtkSeparatorProps, "cssClasses"> & {
  readonly cssClasses?: string[];
};

export const GtkSeparator = (props: GtkSeparatorProps) => {
  const { cssClasses, ...restProps } = props;

  return (
    <_GtkSeparator
      {...restProps}
      cssClasses={cx(cssClasses, "gtk-separator")}
    />
  );
};

type _GtkSeparatorProps = ConstructProps<
  Gtk.Separator,
  Gtk.Separator.ConstructorProps
>;

const _GtkSeparator = astalify<Gtk.Separator, Gtk.Separator.ConstructorProps>(
  Gtk.Separator
);
