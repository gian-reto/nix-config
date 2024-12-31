import { GtkListBox, GtkListBoxProps } from "../../../widgets/GtkListBox";
import {
  GtkListBoxRow,
  GtkListBoxRowProps,
} from "../../../widgets/GtkListBoxRow";

import { Binding } from "astal";
import { Gtk } from "astal/gtk4";
import { PropsWithChildren } from "../../../util/jsx";
import { cx } from "../../../util/cx";

export type ListBoxProps = Omit<
  PropsWithChildren<GtkListBoxProps>,
  "cssClasses"
> & {
  readonly cssClasses?: string[];
  readonly subtitle?: string | Binding<string>;
  readonly title?: string | Binding<string>;
};

const ListBox = (props: ListBoxProps): Gtk.Widget => {
  const { child, children, cssClasses, subtitle, title, ...restProps } = props;

  return (
    <box cssClasses={cx(cssClasses, "space-y-3")} vertical>
      {(title || subtitle) && (
        <box cssClasses={["space-y-0.5"]} vertical>
          {title && (
            <label
              cssClasses={["font-semibold", "text-white", "text-sm"]}
              halign={Gtk.Align.START}
            >
              {title}
            </label>
          )}
          {subtitle && (
            <label
              cssClasses={["font-normal", "text-gray-100", "text-sm"]}
              halign={Gtk.Align.START}
            >
              {subtitle}
            </label>
          )}
        </box>
      )}
      <GtkListBox
        {...restProps}
        cssClasses={[
          "bg-transparent",
          "divide-y",
          "divide-gray-700",
          "rounded-xl",
          "shadow-md",
        ]}
        overflow={Gtk.Overflow.HIDDEN}
      >
        {child || children}
      </GtkListBox>
    </box>
  );
};

export type ListBoxItemProps = PropsWithChildren<GtkListBoxRowProps>;

const ListBoxItem = (props: ListBoxItemProps): Gtk.Widget => {
  const { child, children, cssClasses, ...restProps } = props;

  return (
    <GtkListBoxRow
      {...restProps}
      cssClasses={cx(
        cssClasses,
        "bg-gray-500",
        "first-child:rounded-t-xl",
        "last-child:rounded-b-xl",
        "px-4",
        "py-4"
      )}
    >
      {child || children}
    </GtkListBoxRow>
  );
};

ListBox.Item = ListBoxItem;
export { ListBox };
