import { Gtk } from "astal/gtk4";

export const NotificationCenter = () => {
  return (
    <box cssClasses={["min-w-64", "min-h-64"]}>
      <label>date</label>
      <popover>
        <Gtk.Calendar />
      </popover>
    </box>
  );
};
