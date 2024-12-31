import { App, Astal, Gdk, Gtk } from "astal/gtk4";

import { Variable } from "astal";
import { WorkspaceIndicator } from "../components/atoms/workspace-indicator/WorkspaceIndicator";

const time = Variable("").poll(1000, "date");

export default function Bar(gdkmonitor: Gdk.Monitor) {
  const { TOP, LEFT, RIGHT } = Astal.WindowAnchor;

  return (
    <window
      visible
      cssClasses={["Bar"]}
      gdkmonitor={gdkmonitor}
      exclusivity={Astal.Exclusivity.EXCLUSIVE}
      anchor={TOP | LEFT | RIGHT}
      application={App}
    >
      <centerbox cssName="centerbox">
        <WorkspaceIndicator />
        <button
          onClicked={() => App.toggle_window("notification-center")}
          hexpand
          halign={Gtk.Align.CENTER}
        >
          Welcome to AGS!
        </button>
        {/* <box /> */}
        <menubutton hexpand halign={Gtk.Align.CENTER}>
          <label label={time()} />
          <popover>
            <Gtk.Calendar />
          </popover>
        </menubutton>
      </centerbox>
    </window>
  );
}
