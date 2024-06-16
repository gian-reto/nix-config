import Gdk from "gi://Gdk";
import { TrayItem } from "types/service/systemtray";

const systemtray = await Service.import("systemtray");

export const SystemTray = () => {
  return Widget.Box({
    class_name: "system-tray section horizontal",
  }).bind("children", systemtray, "items", (item) =>
    item
      // TODO: Ignore some unwelcome items.
      // .filter(({ id }) => !ignore.value.includes(id))
      .map(SystemTrayItem)
  );
};

const SystemTrayItem = (item: TrayItem) => {
  return Widget.Button({
    class_name: "item",
    child: Widget.Icon({ class_name: "icon", icon: item.bind("icon") }),
    tooltip_markup: item.bind("tooltip_markup"),
    setup: (self) => {
      const menu = item.menu;
      if (!menu) return;

      // Move the menu down a bit.
      menu.rect_anchor_dy = 4;

      const id = menu.connect("popped-up", () => {
        self.toggleClassName("active");
        menu.connect("notify::visible", () => {
          self.toggleClassName("active", menu.visible);
        });
        menu.disconnect(id);
      });

      if (id) self.connect("destroy", () => menu.disconnect(id));
    },
    on_primary_click: (button) =>
      item.menu?.popup_at_widget(
        button,
        Gdk.Gravity.SOUTH,
        Gdk.Gravity.NORTH,
        null
      ),
    on_secondary_click: (button) =>
      item.menu?.popup_at_widget(
        button,
        Gdk.Gravity.SOUTH,
        Gdk.Gravity.NORTH,
        null
      ),
  });
};
