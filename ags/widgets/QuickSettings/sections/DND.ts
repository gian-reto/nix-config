import { SimpleToggleButton } from "../ToggleButton";
import { icons } from "lib/icons";

const notifications = await Service.import("notifications");
const dnd = notifications.bind("dnd");

export const DND = () => {
  return SimpleToggleButton({
    icon: dnd.as(icon),
    label: dnd.as((dnd) => (dnd ? "Silent" : "Noisy")),
    toggle: () => (notifications.dnd = !notifications.dnd),
    connection: [notifications, () => !notifications.dnd],
  });
};

const icon = (dnd: boolean) =>
  dnd ? icons.notifications.silent : icons.notifications.noisy;
