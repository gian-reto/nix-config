import powermenu, { Action } from "service/powermenu";

import icons from "lib/icons";

const SysButton = (action: Action) =>
  Widget.Button({
    vpack: "center",
    child: Widget.Icon(icons.powermenu[action]),
    on_clicked: () => powermenu.action(action),
  });

export const Header = () =>
  Widget.Box(
    { class_name: "header horizontal" },
    Widget.Box({ hexpand: true }),
    SysButton("logout"),
    SysButton("shutdown")
  );
