import { DateTime } from "./sections/DateTime";
import { SystemTray } from "./sections/SystemTray";
import { Volume } from "./sections/Volume";
import { Workspaces } from "./sections/Workspaces";

export const Bar = (monitor: number = 0) =>
  Widget.Window({
    monitor: monitor,
    class_name: "bar-window",
    name: `bar-${monitor}`, // Note: Name has to be unique.
    exclusivity: "exclusive",
    anchor: ["top", "left", "right"],
    child: Widget.CenterBox({
      class_name: "bar",
      startWidget: Widget.Box({
        hexpand: true,
        vexpand: true,
        hpack: "start",
        children: [Workspaces()],
      }),
      centerWidget: Widget.Box({
        hexpand: true,
        vexpand: true,
        hpack: "center",
        children: [DateTime()],
      }),
      endWidget: Widget.Box({
        hexpand: true,
        vexpand: true,
        hpack: "end",
        children: [SystemTray(), Volume()],
      }),
    }),
  });
