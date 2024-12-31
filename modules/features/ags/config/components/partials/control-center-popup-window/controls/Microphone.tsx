import {
  ToggleButton,
  ToggleButtonProps,
} from "../../../atoms/toggle-button/ToggleButton";
import { Variable, bind, derive } from "astal";

import { Gtk } from "astal/gtk4";
import Wireplumber from "gi://AstalWp";

const wireplumber = Wireplumber.get_default();

export type MicrophoneToggleProps = Omit<
  ToggleButtonProps,
  "expandable" | "iconName" | "label"
>;

export const MicrophoneToggle = (props: MicrophoneToggleProps): Gtk.Widget => {
  const state = wireplumber
    ? derive([bind(wireplumber, "defaultMicrophone")], (defaultMicrophone) => {
        return {
          active: !defaultMicrophone.mute,
          iconName: defaultMicrophone.mute
            ? "microphone-disabled-symbolic"
            : "microphone-sensitivity-high-symbolic",
          label: defaultMicrophone.mute ? "Muted" : "Unmuted",
        };
      })
    : Variable({
        active: false,
        iconName: "microphone-disabled-symbolic",
        label: "Disabled",
      });

  return (
    <ToggleButton
      {...props}
      active={bind(state).as(({ active }) => active)}
      expandable={false}
      iconName={bind(state).as(({ iconName }) => iconName)}
      label={bind(state).as(({ label }) => label)}
      onClicked={() => {
        if (wireplumber) {
          wireplumber.defaultMicrophone.set_mute(
            !wireplumber.defaultMicrophone.mute
          );
        }
      }}
    />
  );
};
