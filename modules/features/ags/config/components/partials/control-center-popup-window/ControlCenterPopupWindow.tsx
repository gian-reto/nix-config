import { Astal, Gdk, Gtk } from "astal/gtk4";
import { Binding, Variable, bind, derive, execAsync } from "astal";
import { BluetoothMenu, BluetoothToggle } from "./controls/Bluetooth";
import { NetworkMenu, NetworkToggle } from "./controls/Network";
import {
  PopupWindow,
  PopupWindowProps,
} from "../../hocs/popup-window/PopupWindow";

import Battery from "gi://AstalBattery";
import Bluetooth from "gi://AstalBluetooth?version=0.1";
import { ButtonProps } from "astal/gtk4/widget";
import { MicrophoneToggle } from "./controls/Microphone";
import Network from "gi://AstalNetwork";
import { PowerMenu } from "./controls/Power";
import { VolumeSlider } from "./controls/Volume";
import { cx } from "../../../util/cx";

const battery = Battery.get_default();
const bluetooth = Bluetooth.get_default();
const network = Network.get_default();

export type ControlCenterPopupWindowProps = Omit<
  PopupWindowProps,
  "anchor" | "name"
>;

export const ControlCenterPopupWindow = (
  props: ControlCenterPopupWindowProps
): Gtk.Widget => {
  const { application, setup, ...restProps } = props;

  const selfRef: Variable<Gtk.Window | undefined> = Variable(undefined);

  const expandedMenuState = Variable<
    "none" | "bluetooth" | "network" | "power"
  >("none");

  return (
    <PopupWindow
      {...restProps}
      name="control-center"
      setup={(self) => {
        setup?.(self);
        selfRef.set(self);
      }}
      anchor="right-top"
      application={application}
      exclusivity={Astal.Exclusivity.EXCLUSIVE}
    >
      {bind(selfRef).as(
        (self) =>
          self && (
            <box
              cssClasses={[
                "bg-gray-600",
                "border",
                "border-gray-500",
                "mt-1.5",
                "mr-1.5",
                // Margins to prevent shadow clipping.
                "ml-6",
                "mb-6",
                "p-4",
                "rounded-4xl",
                "shadow-xl",
                "shadow-black",
              ]}
              overflow={Gtk.Overflow.HIDDEN}
              vertical
            >
              <box>
                <box
                  halign={Gtk.Align.START}
                  hexpand
                  valign={Gtk.Align.CENTER}
                  vexpand={false}
                >
                  <IconButton
                    iconName={bind(
                      derive([
                        bind(battery, "isBattery"),
                        bind(battery, "iconName"),
                      ])
                    ).as(([isBattery, iconName]) =>
                      isBattery ? iconName : "ac-adapter-symbolic"
                    )}
                    label={bind(
                      derive([
                        bind(battery, "isBattery"),
                        bind(battery, "percentage"),
                      ])
                    ).as(([isBattery, percentage]) =>
                      isBattery ? `${percentage}%` : "100%"
                    )}
                  />
                </box>
                <box
                  cssClasses={["space-x-2"]}
                  halign={Gtk.Align.END}
                  hexpand
                  valign={Gtk.Align.CENTER}
                  vexpand={false}
                >
                  <IconButton
                    iconName="applets-screenshooter-symbolic"
                    onClicked={() => {
                      execAsync([
                        "grimblast",
                        "--notify",
                        "--freeze",
                        "copy",
                        "area",
                      ]).catch((error: unknown) => {
                        console.error("Failed to take screenshot: ", error);
                      });
                    }}
                  />
                  <IconButton
                    iconName="system-lock-screen-symbolic"
                    onClicked={() => {
                      execAsync(["hyprlock"]).catch((error: unknown) => {
                        console.error("Failed to lock session: ", error);
                      });
                    }}
                  />
                  <IconButton
                    iconName="weather-clear-night-symbolic"
                    onClicked={() => {
                      execAsync(["systemctl", "suspend"]).catch(
                        (error: unknown) => {
                          console.error("Failed to suspend: ", error);
                        }
                      );
                    }}
                  />
                  <IconButton
                    iconName="system-shutdown-symbolic"
                    onClicked={() =>
                      expandedMenuState.get() === "power"
                        ? expandedMenuState.set("none")
                        : expandedMenuState.set("power")
                    }
                  />
                </box>
              </box>
              <PowerMenu
                revealChild={bind(expandedMenuState).as(
                  (expandedMenu) => expandedMenu === "power"
                )}
              />
              <box cssClasses={["mt-4"]} homogeneous vertical>
                <VolumeSlider cssClasses={["px-1.5"]} />
              </box>
              <box cssClasses={["mt-4", "space-x-2.5"]} homogeneous>
                <NetworkToggle
                  isExpanded={bind(expandedMenuState).as(
                    (expandedMenu) => expandedMenu === "network"
                  )}
                  onCollapsed={() => expandedMenuState.set("none")}
                  onExpanded={() => expandedMenuState.set("network")}
                />
                <BluetoothToggle
                  isExpanded={bind(expandedMenuState).as(
                    (expandedMenu) => expandedMenu === "bluetooth"
                  )}
                  onCollapsed={() => expandedMenuState.set("none")}
                  onExpanded={() => expandedMenuState.set("bluetooth")}
                />
              </box>
              <BluetoothMenu
                active={bind(
                  derive([
                    bind(bluetooth, "isPowered"),
                    bind(bluetooth, "isConnected"),
                  ])
                ).as(([isPowered, isConnected]) => isPowered || isConnected)}
                revealChild={bind(expandedMenuState).as(
                  (expandedMenu) => expandedMenu === "bluetooth"
                )}
                window={self}
              />
              <NetworkMenu
                active={bind(network.wifi, "enabled").as((enabled) => enabled)}
                revealChild={bind(expandedMenuState).as(
                  (expandedMenu) => expandedMenu === "network"
                )}
                window={self}
              />
              <box cssClasses={["mt-3", "space-x-2.5"]} homogeneous>
                <MicrophoneToggle />
                {/* Stub box for spacing. */}
                <box />
              </box>
            </box>
          )
      )}
    </PopupWindow>
  );
};

type IconButtonProps = Omit<ButtonProps, "cssClasses" | "onClicked"> & {
  readonly cssClasses?: string[];
  readonly iconName: string | Binding<string>;
  readonly label?: string | Binding<string>;
  readonly onClicked?: (self: Gtk.Button, state: Gdk.ButtonEvent) => void;
};

const IconButton = (props: IconButtonProps): Gtk.Widget => {
  const { cssClasses, iconName, label, onClicked, ...restProps } = props;

  return (
    <button
      {...restProps}
      cssClasses={cx(
        cssClasses,
        "bg-gray-400",
        "min-w-10",
        "min-h-10",
        "p-px",
        label && "px-4",
        "rounded-full",
        "text-white",
        onClicked && "hover:bg-gray-300"
      )}
      hexpand={false}
      vexpand={false}
      onButtonPressed={(self, event) => {
        onClicked?.(self, event);
      }}
    >
      <box
        cssClasses={["space-x-2"]}
        halign={Gtk.Align.CENTER}
        hexpand={false}
        valign={Gtk.Align.CENTER}
        vexpand={false}
      >
        <image
          cssClasses={["text-xl"]}
          iconName={iconName}
          iconSize={Gtk.IconSize.NORMAL}
          halign={Gtk.Align.CENTER}
          hexpand={false}
          valign={Gtk.Align.CENTER}
          vexpand={false}
        />
        {label && (
          <label
            cssClasses={["font-bold", "text-sm"]}
            label={label}
            halign={Gtk.Align.END}
            hexpand={false}
            valign={Gtk.Align.CENTER}
            vexpand={false}
          />
        )}
      </box>
    </button>
  );
};
