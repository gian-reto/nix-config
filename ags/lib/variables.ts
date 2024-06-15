import GLib from "gi://GLib";

export const clock = Variable(GLib.DateTime.new_now_local(), {
  poll: [5000, () => GLib.DateTime.new_now_local()],
});
