import { Battery } from "./sections/Battery";
import { DateTime } from "./sections/DateTime";
import { SystemButton } from "./sections/SystemButton";
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
        class_name: "group horizontal",
        hexpand: true,
        vexpand: true,
        hpack: "start",
        vpack: "center",
        children: [Workspaces()],
      }),
      centerWidget: Widget.Box({
        class_name: "group horizontal",
        hexpand: true,
        vexpand: true,
        hpack: "center",
        vpack: "center",
        children: [DateTime()],
      }),
      endWidget: Widget.Box({
        class_name: "group horizontal",
        hexpand: true,
        vexpand: true,
        hpack: "end",
        vpack: "center",
        children: [
          Widget.Box({
            class_name: "sub-group horizontal",
            hpack: "center",
            vpack: "center",
            children: [SystemTray()],
          }),
          Widget.Box({
            class_name: "sub-group horizontal",
            hpack: "center",
            vpack: "fill",
            vexpand: true,
            children: [Volume(), Battery()],
          }),
          Widget.Box({
            class_name: "sub-group horizontal",
            hpack: "center",
            vpack: "center",
            children: [SystemButton()],
          }),
        ],
      }),
    }),
  });
