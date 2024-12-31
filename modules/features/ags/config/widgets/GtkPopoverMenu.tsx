import { ConstructProps, Gtk, astalify } from "astal/gtk4";

import { Binding } from "astal";
import { cx } from "../util/cx";

export type GtkPopoverMenuProps = Omit<
  _GtkPopoverMenuProps,
  "cssClasses" | "parent"
> & {
  readonly cssClasses?: string[];
  parent: Gtk.Widget | Binding<Gtk.Widget>;
};

export const GtkPopoverMenu = (props: GtkPopoverMenuProps) => {
  const { cssClasses, parent, ...restProps } = props;

  return (
    <_GtkPopoverMenu
      {...restProps}
      cssClasses={cx(cssClasses, "gtk-popover-menu")}
    />
  );
};

type _GtkPopoverMenuProps = ConstructProps<
  Gtk.PopoverMenu,
  Gtk.PopoverMenu.ConstructorProps
>;

const _GtkPopoverMenu = astalify<
  Gtk.PopoverMenu,
  Gtk.PopoverMenu.ConstructorProps
>(Gtk.PopoverMenu);
