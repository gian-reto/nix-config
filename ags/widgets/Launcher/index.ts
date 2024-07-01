import { AppLauncher, Favorites } from "./AppLauncher";

import { PopupWindow } from "widgets/PopupWindow/index";
import { icons } from "lib/icons";

export const Launcher = () => {
  const favorites = Favorites();
  const appLauncher = AppLauncher();

  const entry = Widget.Entry({
    class_name: "search",
    hexpand: true,
    primary_icon_name: icons.ui.search,
    on_accept: ({ text }) => {
      appLauncher.launchFirst();

      App.toggleWindow("launcher");
      entry.text = "";
    },
    on_change: (self) => {
      if (self.text === "Search" || self.text === "") {
        self.toggleClassName("dirty", false);
      } else {
        self.toggleClassName("dirty", true);
      }

      const query = self.text || "";
      favorites.reveal_child = query === "";

      appLauncher.filter(query);
    },
  });

  const focus = () => {
    entry.text = "Search";
    entry.set_position(-1);
    entry.select_region(0, -1);
    entry.grab_focus();
    favorites.reveal_child = true;
  };

  const layout = Widget.Box({
    css: "min-width: 0pt;",
    class_name: "launcher vertical",
    vertical: true,
    vpack: "start",
    setup: (self) =>
      self.hook(App, (_, win, visible) => {
        if (win !== "launcher") return;

        entry.text = "";
        if (visible) focus();
      }),
    children: [Widget.Box([entry]), favorites, appLauncher],
  });

  return PopupWindow({
    name: "launcher",
    class_name: "launcher",
    layout: "top-center",
    transition: "none",
    child: Widget.Box({ vertical: true, css: "padding: 1px" }, layout),
  });
};
