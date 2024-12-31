import {
  ToggleButtonMenu,
  ToggleButtonMenuItemProps,
  ToggleButtonMenuProps,
} from "../../../atoms/toggle-button/ToggleButton";

import { Gtk } from "astal/gtk4";
import { cx } from "../../../../util/cx";
import { execAsync } from "astal";

export type PowerMenuProps = Omit<ToggleButtonMenuProps, "iconName" | "title">;

export const PowerMenu = (props: PowerMenuProps): Gtk.Widget => {
  const items = [
    {
      label: "Suspend",
      onClicked: () => {
        execAsync(["systemctl", "suspend"]).catch((error: unknown) => {
          console.error("Failed to suspend the system", error);
        });
      },
    },
    {
      label: "Restart",
      onClicked: () => {
        execAsync(["systemctl", "reboot"]).catch((error: unknown) => {
          console.error("Failed to restart the system", error);
        });
      },
    },
    {
      label: "Power Off",
      onClicked: () => {
        execAsync(["shutdown", "now"]).catch((error: unknown) => {
          console.error("Failed to power off the system", error);
        });
      },
    },
  ].map(({ label, onClicked }) => (
    <PowerMenuItem label={label} onClicked={onClicked} />
  ));

  return (
    <ToggleButtonMenu
      {...props}
      footer={
        <PowerMenuItem
          label="Log Out"
          onClicked={() => {
            execAsync(["hyprctl", "dispatch", "exit"]).catch(
              (error: unknown) => {
                console.error("Failed to log out", error);
              }
            );
          }}
        />
      }
      iconName="system-shutdown-symbolic"
      title="Power Off"
    >
      <box hexpand vertical>
        {items}
      </box>
    </ToggleButtonMenu>
  );
};

type PowerMenuItemProps = ToggleButtonMenuItemProps & {
  readonly label: string;
};

const PowerMenuItem = (props: PowerMenuItemProps): Gtk.Widget => {
  const { label, onClicked, cssClasses, ...restProps } = props;

  return (
    <ToggleButtonMenu.Item
      {...restProps}
      cssClasses={cx(cssClasses, "space-x-2")}
      onClicked={onClicked}
    >
      <label
        label={label}
        halign={Gtk.Align.START}
        hexpand
        valign={Gtk.Align.CENTER}
        vexpand={false}
      />
    </ToggleButtonMenu.Item>
  );
};
