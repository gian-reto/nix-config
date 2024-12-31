import { Variable, bind, derive } from "astal";

import { BoxProps } from "astal/gtk4/widget";
import { Gtk } from "astal/gtk4";
import { GtkScale } from "../../../../widgets/GtkScale";
import Wireplumber from "gi://AstalWp";
import { cx } from "../../../../util/cx";

const wireplumber = Wireplumber.get_default();

export type VolumeSliderProps = Omit<BoxProps, "cssClasses"> & {
  readonly cssClasses?: string[];
};

export const VolumeSlider = (props: VolumeSliderProps): Gtk.Widget => {
  const { cssClasses, ...restProps } = props;

  const volumeState = wireplumber
    ? derive(
        [
          bind(wireplumber, "defaultSpeaker"),
          bind(wireplumber.defaultSpeaker, "volume"),
          bind(wireplumber.defaultSpeaker, "volumeIcon"),
        ],
        (defaultSpeaker, volume, volumeIcon) => ({
          value: volume,
          iconName: volumeIcon,
        })
      )
    : Variable(undefined);

  return (
    <box {...restProps} cssClasses={cx(cssClasses, "space-x-2")}>
      <image
        halign={Gtk.Align.START}
        hexpand={false}
        iconName={bind(volumeState).as((volume) =>
          volume === undefined ? "audio-volume-muted-symbolic" : volume.iconName
        )}
        valign={Gtk.Align.CENTER}
        vexpand={false}
      />
      <GtkScale
        setup={(self) => {
          self.set_range(0, 1);

          volumeState.subscribe((volume) => {
            if (volume === undefined) {
              // self.set_sensitive(false);
              self.set_value(0);
              return;
            }
            // self.set_sensitive(true);
            self.set_value(volume.value);
          });

          self.connect("value-changed", (self) => {
            if (!wireplumber) return;

            wireplumber.defaultSpeaker.set_volume(self.get_value());
          });
        }}
        cssClasses={["p-0"]}
        halign={Gtk.Align.FILL}
        hexpand
        valign={Gtk.Align.CENTER}
        vexpand={false}
      />
    </box>
  );
};
