import { ConstructProps, Gtk, astalify } from "astal/gtk4";

import { cx } from "../util/cx";

export type GtkScrolledWindowProps = Omit<
  _GtkScrolledWindowProps,
  "cssClasses"
> & {
  readonly cssClasses?: string[];
};

export const GtkScrolledWindow = (props: GtkScrolledWindowProps) => {
  const { cssClasses, ...restProps } = props;

  return (
    <_GtkScrolledWindow
      {...restProps}
      cssClasses={cx(cssClasses, "gtk-scrolledwindow")}
    />
  );
};

type _GtkScrolledWindowProps = ConstructProps<
  Gtk.ScrolledWindow,
  Gtk.ScrolledWindow.ConstructorProps
>;

const _GtkScrolledWindow = astalify<
  Gtk.ScrolledWindow,
  Gtk.ScrolledWindow.ConstructorProps
>(Gtk.ScrolledWindow);
