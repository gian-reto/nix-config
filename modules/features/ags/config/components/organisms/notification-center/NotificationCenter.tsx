import {
  NotificationList,
  NotificationListProps,
} from "../../molecules/notification-list/NotificationList";
import { Variable, bind, derive } from "astal";

import { BoxProps } from "astal/gtk4/widget";
import { Gtk } from "astal/gtk4";
import { GtkCalendar } from "../../../widgets/GtkCalendar";
import { MusicPlayer } from "../../molecules/music-player/MusicPlayer";
import Notifd from "gi://AstalNotifd";
import { WorldClocksList } from "../../molecules/world-clocks-list/WorldClocksList";
import { cx } from "../../../util/cx";

const currentDateTimeState = Variable("").poll(
  // Poll every minute.
  1000 * 60,
  'date +"%A %d %B %Y"'
);

const notifd = Notifd.get_default();

export type NotificationCenterProps = Omit<BoxProps, "cssClasses"> &
  Pick<NotificationListProps, "window"> & {
    readonly cssClasses?: string[];
  };

export const NotificationCenter = (props: NotificationCenterProps) => {
  const { cssClasses, setup, window } = props;

  const doNotDisturbState = derive([bind(notifd, "dontDisturb")], (dnd) => dnd);

  return (
    <box
      setup={(self) => {
        setup?.(self);

        // Initially disable polling.
        currentDateTimeState.stopPoll();

        bind(window, "visible").subscribe((visible) => {
          if (visible) {
            currentDateTimeState.startPoll();
          } else {
            currentDateTimeState.stopPoll();
          }
        });
      }}
      cssClasses={cx(cssClasses, "divide-x", "divide-gray-500")}
    >
      <box
        cssClasses={["p-3"]}
        valign={Gtk.Align.FILL}
        vexpand={false}
        vertical
      >
        <MusicPlayer cssClasses={["mb-3"]} />
        <box
          cssClasses={["mb-3"]}
          halign={Gtk.Align.FILL}
          valign={Gtk.Align.FILL}
          vexpand
        >
          <NotificationList window={window} />
        </box>
        <box
          halign={Gtk.Align.FILL}
          hexpand
          valign={Gtk.Align.END}
          vexpand={false}
        >
          <box
            cssClasses={["ml-1.5", "space-x-3"]}
            halign={Gtk.Align.START}
            hexpand={false}
            valign={Gtk.Align.CENTER}
            vexpand={false}
          >
            <label cssClasses={["text-sm", "font-semibold", "text-white"]}>
              Do Not Disturb
            </label>
            <switch
              setup={(self) => {
                self.connect("state-set", (self, state) =>
                  notifd.set_dont_disturb(state)
                );
              }}
              active={bind(doNotDisturbState)}
              valign={Gtk.Align.CENTER}
              vexpand={false}
            />
          </box>
          <box
            halign={Gtk.Align.END}
            hexpand
            valign={Gtk.Align.CENTER}
            vexpand={false}
          >
            <button
              cssClasses={["rounded-lg"]}
              halign={Gtk.Align.END}
              hexpand={false}
              valign={Gtk.Align.CENTER}
              vexpand={false}
              onButtonPressed={() => {
                notifd.notifications.forEach((notification) =>
                  notification.dismiss()
                );
              }}
            >
              Clear All
            </button>
          </box>
        </box>
      </box>
      <box cssClasses={["bg-gray-700", "p-3", "space-y-3"]} vertical>
        <box cssClasses={["mt-1", "ml-1.5", "mb-1"]} vertical>
          <label
            cssClasses={["text-sm", "font-bold", "text-gray-100"]}
            halign={Gtk.Align.START}
          >
            {bind(currentDateTimeState).as(
              (currentDateTime) => currentDateTime.split(" ", 1)[0]
            )}
          </label>
          <label
            cssClasses={["text-lg", "font-bold", "text-gray-100"]}
            halign={Gtk.Align.START}
          >
            {bind(currentDateTimeState).as((currentDateTime) =>
              currentDateTime.split(" ").slice(1).join(" ")
            )}
          </label>
        </box>
        <GtkCalendar />
        <WorldClocksList cssClasses={["mt-4"]} window={window} />
      </box>
    </box>
  );
};
