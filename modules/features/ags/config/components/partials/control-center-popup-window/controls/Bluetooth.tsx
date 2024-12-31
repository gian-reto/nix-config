import {
  ToggleButton,
  ToggleButtonMenu,
  ToggleButtonMenuItemProps,
  ToggleButtonMenuProps,
  ToggleButtonProps,
} from "../../../atoms/toggle-button/ToggleButton";
import { bind, derive, execAsync } from "astal";

import Bluetooth from "gi://AstalBluetooth?version=0.1";
import { Gtk } from "astal/gtk4";
import { GtkSpinner } from "../../../../widgets/GtkSpinner";
import { cx } from "../../../../util/cx";
import { debounce } from "../../../../util/debounce";
import { unreachable } from "../../../../util/unreachable";

const bluetooth = Bluetooth.get_default();

export type BluetoothToggleProps = Omit<
  ToggleButtonProps,
  "expandable" | "iconName" | "label"
>;

export const BluetoothToggle = (props: BluetoothToggleProps): Gtk.Widget => {
  const state = derive(
    [
      bind(bluetooth.adapter, "powered"),
      bind(bluetooth, "isConnected"),
      bind(bluetooth, "devices"),
    ],
    (isPowered, isConnected, devices) => {
      const connectedDeviceName =
        devices.length > 0
          ? devices.find((device) => device.connected)
          : undefined;

      return {
        active: isPowered || isConnected,
        connectedDevice: connectedDeviceName,
        iconName:
          isPowered || isConnected
            ? "bluetooth-active-symbolic"
            : "bluetooth-disabled-symbolic",
        label:
          connectedDeviceName?.alias || (isPowered ? "Bluetooth" : "Disabled"),
      };
    }
  );

  return (
    <ToggleButton
      {...props}
      active={bind(state).as(({ active }) => active)}
      expandable
      iconName={bind(state).as(({ iconName }) => iconName)}
      label={bind(state).as(({ label }) => label)}
      onClicked={() => bluetooth.toggle()}
    />
  );
};

export type BluetoothMenuProps = Omit<
  ToggleButtonMenuProps,
  "iconName" | "title"
> & {
  /**
   * Reference to the parent window.
   */
  readonly window: Gtk.Window;
};

export const BluetoothMenu = (props: BluetoothMenuProps): Gtk.Widget => {
  const { window, ...restProps } = props;

  const items = bind(bluetooth, "devices").as((devices) =>
    devices
      .filter((device) => !!device.alias)
      .map((device) => <BluetoothMenuItem device={device} />)
  );

  return (
    <ToggleButtonMenu
      {...restProps}
      setup={(self) => {
        bind(self, "revealChild").subscribe((revealChild) => {
          if (!bluetooth.adapter.powered) return;

          if (revealChild && !bluetooth.adapter.discovering) {
            try {
              bluetooth.adapter.start_discovery();
            } catch (error: unknown) {
              console.error(
                "Failed to start bluetooth discovery. Trigger: revealer expanded. Error: ",
                error
              );
            }
            return;
          }

          if (!revealChild && bluetooth.adapter.discovering) {
            bluetooth.adapter.stop_discovery();
          }
        });

        bind(window, "visible").subscribe((visible) => {
          if (!bluetooth.adapter.powered) return;

          if (visible && self.revealChild && !bluetooth.adapter.discovering) {
            try {
              bluetooth.adapter.start_discovery();
            } catch (error: unknown) {
              console.error(
                "Failed to start bluetooth discovery. Trigger: window became active. Error: ",
                error
              );
            }
            return;
          }

          if (!visible && bluetooth.adapter.discovering) {
            bluetooth.adapter.stop_discovery();
          }
        });
      }}
      iconName="bluetooth-active-symbolic"
      spinning={bind(bluetooth.adapter, "discovering")}
      title="Bluetooth"
    >
      <box hexpand vertical>
        {bind(items).as((items) =>
          items.length > 0 ? (
            items
          ) : (
            <label cssClasses={["pt-1", "pb-3"]} label="No devices found" />
          )
        )}
      </box>
    </ToggleButtonMenu>
  );
};

type BluetoothMenuItemProps = ToggleButtonMenuItemProps & {
  readonly device: Bluetooth.Device;
};

const BluetoothMenuItem = (props: BluetoothMenuItemProps): Gtk.Widget => {
  const { cssClasses, device, ...restProps } = props;

  const setConnectionOrPairing = (
    targetState: "on" | "off",
    device: Bluetooth.Device
  ): void => {
    // Prevent setting connection or pairing again while connecting.
    if (device.get_connecting()) return;

    switch (targetState) {
      case "on":
        if (device.get_connected()) {
          // Already connected.
          return;
        }

        if (device.get_paired()) {
          connectDevice(device);
        }

        // Pair and connect.
        try {
          device.pair();
        } catch (error: unknown) {
          console.error("Failed to pair device: ", error);
        }
        break;

      case "off":
        if (device.get_connected()) {
          disconnectDevice(device);
        }
        break;

      default:
        unreachable(targetState);
    }
  };

  const debouncedSetConnectionOrPairing = debounce(setConnectionOrPairing, {
    waitForMs: 1_000,
    immediate: true,
  });

  return (
    <ToggleButtonMenu.Item
      {...restProps}
      cssClasses={cx(cssClasses, "space-x-2")}
    >
      <image
        iconName={bind(device, "icon")}
        halign={Gtk.Align.START}
        hexpand={false}
        valign={Gtk.Align.CENTER}
        vexpand={false}
        visible={bind(device, "icon").as((icon) => !!icon)}
      />
      <label
        label={bind(device, "alias")}
        halign={Gtk.Align.START}
        hexpand
        valign={Gtk.Align.CENTER}
        vexpand={false}
      />
      <GtkSpinner
        cssClasses={["text-white"]}
        halign={Gtk.Align.END}
        hexpand={false}
        spinning={bind(device, "connecting")}
        valign={Gtk.Align.CENTER}
        vexpand={false}
        visible={bind(device, "connecting")}
      />
      <switch
        setup={(self) => {
          self.connect("state-set", (self, state) => {
            debouncedSetConnectionOrPairing(state ? "on" : "off", device);
          });
        }}
        active={bind(device, "connected")}
        halign={Gtk.Align.END}
        hexpand={false}
        valign={Gtk.Align.CENTER}
        vexpand={false}
      />
    </ToggleButtonMenu.Item>
  );
};

const connectDevice = (device: Bluetooth.Device): void => {
  // TODO: Seems to fail right now. Investigate later.
  //
  // device.connect_device().catch((error: unknown) => {
  //   console.error("Failed to connect device: ", error);
  // });
  execAsync(["bluetoothctl", "connect", device.get_address()]).catch(
    (error: unknown) => {
      console.error("Failed to connect device: ", error);
    }
  );
  return;
};

const disconnectDevice = (device: Bluetooth.Device): void => {
  // TODO: Seems to fail right now. Investigate later.
  //
  // device.disconnect_device().catch((error: unknown) => {
  //   console.error("Failed to disconnect device: ", error);
  // });
  execAsync(["bluetoothctl", "disconnect", device.get_address()]).catch(
    (error: unknown) => {
      console.error("Failed to disconnect device: ", error);
    }
  );
};
