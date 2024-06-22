import { BluetoothMenu, BluetoothToggle } from "./sections/Bluetooth";
import { NetworkMenu, NetworkToggle } from "./sections/Network";

import type Gtk from "gi://Gtk?version=3.0";
import { Header } from "./sections/Header";
import { Media } from "./sections/Media";
import { Mic } from "./sections/Mic";
import { PopupWindow } from "widgets/PopupWindow/index";

const media = (await Service.import("mpris")).bind("players");
const layout = "top-right";

export function setupQuickSettings() {
  App.addWindow(QuickSettings());
}

const QuickSettings = () => {
  return PopupWindow({
    name: "quicksettings",
    exclusivity: "exclusive",
    transition: "slide_down",
    layout,
    child: Settings(),
  });
};

const Row = (
  toggles: Array<() => Gtk.Widget> = [],
  menus: Array<() => Gtk.Widget> = []
) => {
  return Widget.Box({
    vertical: true,
    children: [
      Widget.Box({
        homogeneous: true,
        class_name: "row horizontal",
        children: toggles.map((w) => w()),
      }),
      ...menus.map((w) => w()),
    ],
  });
};

const Settings = () => {
  return Widget.Box({
    vertical: true,
    class_name: "quicksettings vertical",
    children: [
      Header(),
      Row([NetworkToggle, BluetoothToggle], [NetworkMenu, BluetoothMenu]),
      Row([Mic]),
      Widget.Box({
        hpack: "fill",
        hexpand: true,
        visible: media.as((players) => players.length > 0),
        child: Media(),
      }),
    ],
  });
};
