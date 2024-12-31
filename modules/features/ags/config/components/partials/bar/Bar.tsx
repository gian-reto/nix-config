import { App, Astal, Gdk, Gtk } from "astal/gtk4";
import { Variable, bind, derive } from "astal";

import NM from "gi://NM?version=1.0";
import Network from "gi://AstalNetwork";
import { Tray } from "../../molecules/tray/Tray";
import { WindowProps } from "astal/gtk4/widget";
import Wireplumber from "gi://AstalWp";
import { WorkspaceIndicator } from "../../atoms/workspace-indicator/WorkspaceIndicator";
import { cx } from "../../../util/cx";
import { getIconNameForDeviceType } from "../../../util/network-manager";
import { unreachable } from "../../../util/unreachable";

const network = Network.get_default();
const wireplumber = Wireplumber.get_default();

const time = Variable("").poll(1000, 'date --iso-8601="minutes"');

export type BarProps = Omit<WindowProps, "application" | "exclusivity"> & {
  /**
   * The application which the window belongs to.
   */
  readonly application: NonNullable<WindowProps["application"]>;
  readonly cssClasses?: string[];
  /**
   * The monitor where the window is displayed.
   */
  readonly gdkmonitor: Gdk.Monitor;
};

export default function Bar(props: BarProps) {
  const { application, cssClasses, gdkmonitor, name } = props;

  const { TOP, LEFT, RIGHT } = Astal.WindowAnchor;

  const audioState = wireplumber
    ? derive(
        [
          bind(wireplumber, "defaultSpeaker"),
          bind(wireplumber.defaultSpeaker, "mute"),
          bind(wireplumber.defaultSpeaker, "volume"),
          bind(wireplumber.defaultSpeaker, "volumeIcon"),
          bind(wireplumber, "defaultMicrophone"),
          bind(wireplumber.defaultMicrophone, "mute"),
        ],
        (
          defaultSpeaker,
          speakerMuted,
          speakerVolume,
          speakerVolumeIcon,
          defaultMicrophone,
          microphoneMuted
        ) => ({
          speakerMuted,
          speakerVolume,
          speakerVolumeIcon,
          microphoneMuted,
        })
      )
    : Variable(undefined);

  return (
    <window
      anchor={TOP | LEFT | RIGHT}
      application={application}
      cssClasses={cx(cssClasses, "bg-black", "text-white")}
      exclusivity={Astal.Exclusivity.EXCLUSIVE}
      gdkmonitor={gdkmonitor}
      name={name ?? "bar"}
      visible
    >
      <centerbox>
        <WorkspaceIndicator
          cssClasses={["pl-3"]}
          halign={Gtk.Align.START}
          hexpand={false}
          valign={Gtk.Align.CENTER}
          vexpand={false}
        />

        <button
          cssClasses={[
            "bg-transparent",
            "font-bold",
            "my-0.5",
            "px-3",
            "py-0.5",
            "rounded-full",
            "text-sm",
            "text-white",
            "hover:bg-gray-800",
          ]}
          halign={Gtk.Align.CENTER}
          hexpand={false}
          valign={Gtk.Align.CENTER}
          vexpand={false}
          onClicked={() => App.toggle_window("notification-center")}
        >
          {bind(time).as((time) =>
            new Date(time).toLocaleTimeString(undefined, {
              month: "short",
              day: "numeric",
              hour: "2-digit",
              hour12: false,
              minute: "2-digit",
            })
          )}
        </button>

        <box
          cssClasses={["pr-1.5", "space-x-4"]}
          halign={Gtk.Align.END}
          hexpand={false}
        >
          <Tray
            extraItems={[
              {
                iconName: "system-search-symbolic",
                tooltipMarkup: "Launcher",
                onClicked: () => {
                  App.toggle_window("launcher");
                },
              },
            ]}
            halign={Gtk.Align.END}
            hexpand={false}
            valign={Gtk.Align.CENTER}
            vexpand={false}
          />

          <box
            cssClasses={[
              "bg-transparent",
              "my-0.5",
              "px-3",
              "py-1.5",
              "rounded-full",
              "space-x-3",
              "hover:bg-gray-800",
            ]}
            halign={Gtk.Align.END}
            hexpand={false}
            valign={Gtk.Align.CENTER}
            vexpand={false}
            onButtonPressed={() => App.toggle_window("control-center")}
          >
            <image
              iconName={bind(network, "client").as((client) => {
                switch (client.connectivity) {
                  case NM.ConnectivityState.NONE:
                  case NM.ConnectivityState.PORTAL:
                  case NM.ConnectivityState.UNKNOWN:
                    return "network-offline-symbolic";

                  case NM.ConnectivityState.LIMITED:
                    return "network-no-route-symbolic";

                  case NM.ConnectivityState.FULL:
                    // Ignore this case to return the correct device icon below.
                    break;

                  default:
                    return unreachable(client.connectivity);
                }

                const device = client.primaryConnection.get_devices()[0];
                return getIconNameForDeviceType(device.deviceType);
              })}
            />
            <image
              iconName={bind(audioState).as((audio) => {
                if (!audio || audio.speakerMuted) {
                  return "audio-volume-muted-symbolic";
                }

                return audio.speakerVolumeIcon;
              })}
            />
            <image
              iconName={bind(audioState).as((audio) => {
                if (!audio || audio.microphoneMuted) {
                  return "microphone-disabled-symbolic";
                }

                return "microphone-sensitivity-high-symbolic";
              })}
            />
            <image iconName="system-shutdown-symbolic" />
          </box>
        </box>
      </centerbox>
    </window>
  );
}
