import { Astal, Gtk } from "astal/gtk4";
import {
  PopupWindow,
  PopupWindowProps,
} from "../../hocs/popup-window/PopupWindow";

import { NotificationCenter } from "../../organisms/notification-center/NotificationCenter";
import { cx } from "../../../util/cx";

export type NotificationCenterPopupWindowProps = Omit<
  PopupWindowProps,
  "anchor" | "name"
>;

export const NotificationCenterPopupWindow = (
  props: NotificationCenterPopupWindowProps
): Gtk.Widget => {
  const { application, ...restProps } = props;

  return (
    <PopupWindow
      {...restProps}
      name="notification-center"
      anchor="center-top"
      application={application}
      exclusivity={Astal.Exclusivity.EXCLUSIVE}
    >
      <box cssClasses={["bg-gray-50", "mt-1.5"]}>
        <NotificationCenter />
      </box>
    </PopupWindow>
  );
};
