import { icons } from "lib/icons";

export const Header = () => {
  return Widget.Box(
    { class_name: "header horizontal" },
    Widget.Box({ hexpand: true }),
    SysButton("logout"),
    SysButton("sleep"),
    SysButton("reboot"),
    SysButton("shutdown")
  );
};

const SysButton = (action: Action) => {
  return Widget.Button({
    vpack: "center",
    child: Widget.Icon(icons.powermenu[action]),
    on_clicked: () => {
      Utils.exec(CMD[action]);
    },
  });
};

type Action = "sleep" | "reboot" | "logout" | "shutdown";

const CMD: {
  [key in Action]: string;
} = {
  sleep: "systemctl suspend",
  reboot: "systemctl reboot",
  logout: "pkill Hyprland",
  shutdown: "shutdown now",
};
