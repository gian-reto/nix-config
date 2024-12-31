import { Astal, Gtk } from "astal/gtk4";
import {
  PopupWindow,
  PopupWindowProps,
} from "../../hocs/popup-window/PopupWindow";
import { Variable, bind } from "astal";

import { NotificationCenter } from "../../organisms/notification-center/NotificationCenter";

export type NotificationCenterPopupWindowProps = Omit<
  PopupWindowProps,
  "anchor" | "name"
>;

export const NotificationCenterPopupWindow = (
  props: NotificationCenterPopupWindowProps
): Gtk.Widget => {
  const { application, setup, ...restProps } = props;

  const selfRef: Variable<Gtk.Window | undefined> = Variable(undefined);

  return (
    <PopupWindow
      {...restProps}
      name="notification-center"
      setup={(self) => {
        setup?.(self);
        selfRef.set(self);
      }}
      anchor="center-top"
      application={application}
      exclusivity={Astal.Exclusivity.EXCLUSIVE}
    >
      <box
        cssClasses={[
          "bg-gray-600",
          "border",
          "border-gray-500",
          "mt-1.5",
          // Margins to prevent shadow clipping.
          "ml-6",
          "mr-6",
          "mb-6",
          "rounded-3xl",
          "shadow-xl",
          "shadow-black",
        ]}
        overflow={Gtk.Overflow.HIDDEN}
      >
        {bind(selfRef).as(
          (self) => self && <NotificationCenter window={self} />
        )}
      </box>
    </PopupWindow>
  );
};
