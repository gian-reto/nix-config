import { Binding, bind } from "astal";
import { BoxProps, MenuButtonProps } from "astal/gtk4/widget";

import AstalTray from "gi://AstalTray";
import { Gtk } from "astal/gtk4";
import { cx } from "../../../util/cx";
import { unreachable } from "../../../util/unreachable";

const tray = AstalTray.get_default();

export type TrayProps = Omit<BoxProps, "cssClasses"> & {
  readonly cssClasses?: Array<string>;
  readonly extraItems?: Array<CustomTrayItem["data"]>;
};

export const Tray = (props: TrayProps): Gtk.Widget => {
  const { cssClasses, extraItems, ...restProps } = props;

  return (
    <box {...restProps} cssClasses={cx(cssClasses, "space-x-1")}>
      {bind(tray, "items").as((items) =>
        items.map((item) => <TrayItem item={{ type: "astal", data: item }} />)
      )}
      {extraItems &&
        extraItems.map((item) => (
          <TrayItem item={{ type: "custom", data: item }} />
        ))}
    </box>
  );
};

type AstalTrayItem = {
  readonly type: "astal";
  readonly data: AstalTray.TrayItem;
};

type CustomTrayItem = {
  readonly type: "custom";
  readonly data: {
    readonly iconName: string | Binding<string>;
    readonly tooltipMarkup?: string | Binding<string>;
    readonly onClicked?: () => void;
  };
};

type TrayItemProps = Omit<MenuButtonProps, "cssClasses"> & {
  readonly cssClasses?: Array<string>;
  readonly item: AstalTrayItem | CustomTrayItem;
};

const TrayItem = (props: TrayItemProps): Gtk.Widget => {
  const { cssClasses, item, ...restProps } = props;

  const updateMenu = (self: Gtk.MenuButton, item: AstalTray.TrayItem) => {
    if (!item.menuModel || item.menuModel.get_n_items() < 1) {
      self.set_menu_model(null);
      self.insert_action_group("dbusmenu", null);
      return;
    }

    self.set_menu_model(item.menuModel);
    self.insert_action_group("dbusmenu", item.actionGroup);
  };

  return (
    <menubutton
      {...restProps}
      setup={(self) => {
        switch (item.type) {
          case "astal":
            // Update menu once at the beginning.
            updateMenu(self, item.data);

            item.data.connect("changed", (item) => {
              updateMenu(self, item);
            });
            break;

          case "custom":
            // Do nothing.
            break;

          default:
            unreachable(item);
        }
      }}
      cssClasses={cx(
        cssClasses,
        "gtk-menubutton",
        "bg-transparent",
        "min-w-7",
        "min-h-7",
        "p-0",
        "rounded-full",
        "transition-colors",
        "hover:bg-gray-800"
      )}
      halign={Gtk.Align.CENTER}
      hexpand={false}
      valign={Gtk.Align.CENTER}
      vexpand={false}
      tooltipMarkup={
        item.type === "astal"
          ? bind(item.data, "tooltipMarkup")
          : item.data.tooltipMarkup
      }
      onButtonPressed={() => {
        if (item.type === "custom") {
          item.data.onClicked?.();
        }
      }}
    >
      {item.type === "astal" ? (
        <image gicon={bind(item.data, "gicon")} />
      ) : (
        <image iconName={item.data.iconName} />
      )}
    </menubutton>
  );
};
