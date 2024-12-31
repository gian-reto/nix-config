import { ConstructProps, Gtk, astalify } from "astal/gtk4";

import { cx } from "../util/cx";

export type GtkSpinnerProps = Omit<_GtkSpinnerProps, "cssClasses"> & {
  readonly cssClasses?: string[];
};

export const GtkSpinner = (props: GtkSpinnerProps) => {
  const { cssClasses, ...restProps } = props;

  return (
    <_GtkSpinner {...restProps} cssClasses={cx(cssClasses, "gtk-spinner")} />
  );
};

type _GtkSpinnerProps = ConstructProps<
  Gtk.Spinner,
  Gtk.Spinner.ConstructorProps
>;

const _GtkSpinner = astalify<Gtk.Spinner, Gtk.Spinner.ConstructorProps>(
  Gtk.Spinner
);
