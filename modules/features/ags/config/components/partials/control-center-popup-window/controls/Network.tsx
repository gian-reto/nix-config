import { Astal, Gdk, Gtk } from "astal/gtk4";
import { Binding, bind, derive, execAsync } from "astal";
import {
  ToggleButton,
  ToggleButtonMenu,
  ToggleButtonMenuItemProps,
  ToggleButtonMenuProps,
  ToggleButtonProps,
} from "../../../atoms/toggle-button/ToggleButton";
import {
  getIconNameForDeviceType,
  getLabelForDeviceType,
} from "../../../../util/network-manager";

import Network from "gi://AstalNetwork";
import { cx } from "../../../../util/cx";

const network = Network.get_default();

export type NetworkToggleProps = Omit<
  ToggleButtonProps,
  "active" | "expandable" | "iconName" | "label" | "onClicked"
> & {
  readonly onClicked?: (self: Astal.Box, state: Gdk.ButtonEvent) => void;
};

export const NetworkToggle = (props: NetworkToggleProps): Gtk.Widget => {
  const { onClicked, ...restProps } = props;

  const state = derive(
    [
      bind(network, "client"),
      bind(network.wifi, "enabled"),
      bind(network.wifi, "ssid"),
    ],
    (client, enabled, ssid) => {
      const device = client.primaryConnection.get_devices()[0];

      return {
        active: enabled,
        iconName: getIconNameForDeviceType(device.deviceType),
        label: ssid || getLabelForDeviceType(device.deviceType),
      };
    }
  );

  return (
    <ToggleButton
      {...restProps}
      active={bind(state).as(({ active }) => active)}
      expandable
      iconName={bind(state).as(({ iconName }) => iconName)}
      label={bind(state).as(({ label }) => label)}
      onClicked={(self, state) => {
        onClicked?.(self, state);

        network.wifi.enabled = !network.wifi.enabled;
      }}
    />
  );
};

export type NetworkMenuProps = Omit<
  ToggleButtonMenuProps,
  "iconName" | "title"
> & {
  /**
   * Reference to the parent window.
   */
  readonly window: Gtk.Window;
};

export const NetworkMenu = (props: NetworkMenuProps): Gtk.Widget => {
  const { window, ...restProps } = props;

  const items = bind(
    derive([
      bind(network.wifi, "accessPoints"),
      bind(network.wifi, "activeAccessPoint"),
    ])
  ).as(([accessPoints, activeAccessPoint]) =>
    accessPoints
      .reduce<Array<Network.AccessPoint>>((acc, accessPoint) => {
        return acc.some((ap) => ap.ssid === accessPoint.ssid)
          ? acc
          : !!accessPoint.ssid
          ? [...acc, accessPoint]
          : acc;
      }, [])
      .sort((a, b) => b.strength - a.strength)
      .slice(0, 10)
      .map((accessPoint) => (
        <NetworkMenuItem
          accessPoint={accessPoint}
          active={accessPoint === activeAccessPoint}
        />
      ))
  );

  return (
    <ToggleButtonMenu
      {...restProps}
      setup={(self) => {
        bind(self, "revealChild").subscribe((revealChild) => {
          if (!network.wifi.enabled) return;

          if (revealChild) {
            network.wifi.scan();
          }
        });

        bind(window, "visible").subscribe((visible) => {
          if (!network.wifi.enabled) return;

          if (visible && self.revealChild) {
            network.wifi.scan();
          }
        });
      }}
      iconName="network-wireless-symbolic"
      spinning={bind(network.wifi, "scanning")}
      title="Wi-Fi"
    >
      <box hexpand vertical>
        {bind(items).as((items) =>
          items.length > 0 ? (
            items
          ) : (
            <label cssClasses={["pt-1", "pb-3"]} label="No networks found" />
          )
        )}
      </box>
    </ToggleButtonMenu>
  );
};

type NetworkMenuItemProps = ToggleButtonMenuItemProps & {
  readonly accessPoint: Network.AccessPoint;
  readonly active: boolean | Binding<boolean>;
};

const NetworkMenuItem = (props: NetworkMenuItemProps): Gtk.Widget => {
  const { accessPoint, active, cssClasses, ...restProps } = props;

  return (
    <ToggleButtonMenu.Item
      {...restProps}
      cssClasses={cx(cssClasses, "space-x-2")}
      onClicked={() => {
        if (active) {
          execAsync(["nmcli", "connection", "down", accessPoint.ssid]).catch(
            (error: unknown) => {
              console.error("Failed to disconnect from network: ", error);
            }
          );
        } else {
          execAsync([
            "nmcli",
            "device",
            "wifi",
            "connect",
            accessPoint.ssid,
          ]).catch((error: unknown) => {
            console.error("Failed to connect to network: ", error);
          });
        }
      }}
    >
      <image
        iconName={bind(accessPoint, "iconName")}
        halign={Gtk.Align.START}
        hexpand={false}
        valign={Gtk.Align.CENTER}
        vexpand={false}
      />
      <label
        label={bind(accessPoint, "ssid")}
        halign={Gtk.Align.START}
        hexpand
        valign={Gtk.Align.CENTER}
        vexpand={false}
      />
      <image
        iconName="object-select-symbolic"
        halign={Gtk.Align.END}
        hexpand={false}
        valign={Gtk.Align.CENTER}
        vexpand={false}
        visible={active}
      />
    </ToggleButtonMenu.Item>
  );
};
