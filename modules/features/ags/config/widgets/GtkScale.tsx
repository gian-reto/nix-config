import { ConstructProps, Gtk, astalify } from "astal/gtk4";

import { cx } from "../util/cx";

export type GtkScaleProps = Omit<_GtkScaleProps, "cssClasses"> & {
  readonly cssClasses?: string[];
};

export const GtkScale = (props: GtkScaleProps) => {
  const { cssClasses, ...restProps } = props;

  return <_GtkScale {...restProps} cssClasses={cx(cssClasses, "gtk-scale")} />;
};

type _GtkScaleProps = ConstructProps<Gtk.Scale, Gtk.Scale.ConstructorProps>;

const _GtkScale = astalify<Gtk.Scale, Gtk.Scale.ConstructorProps>(Gtk.Scale);
