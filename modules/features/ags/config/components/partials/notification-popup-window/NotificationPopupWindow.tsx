import { Astal, Gtk } from "astal/gtk4";
import { Variable, bind, timeout } from "astal";

import { GtkScrolledWindow } from "../../../widgets/GtkScrolledWindow";
import Notifd from "gi://AstalNotifd?version=0.1";
import { Notification } from "../../atoms/notification/Notification";
import { WindowProps } from "astal/gtk4/widget";

const TRANSITION_DURATION_MS = 200;

export type NotificationPopupWindowProps = Omit<
  WindowProps,
  | "anchor"
  | "application"
  | "child"
  | "cssClasses"
  | "exclusivity"
  | "focusable"
  | "keymode"
  | "layer"
  | "name"
> & {
  /**
   * The application which the window belongs to.
   */
  readonly application: NonNullable<WindowProps["application"]>;
  readonly notification: Notifd.Notification;
};

export const NotificationPopupWindow = (
  props: NotificationPopupWindowProps
): Gtk.Widget => {
  const { application, notification, setup, ...restProps } = props;

  const { LEFT, RIGHT, TOP } = Astal.WindowAnchor;

  const selfRef: Variable<Gtk.Window | undefined> = Variable(undefined);

  const childRevealedState = Variable(false);

  /**
   * Destroy the window, but don't dismiss the notification to keep it in the
   * notification center.
   */
  const destroySelf = (self: Gtk.Window) => {
    childRevealedState.set(false);
    timeout(TRANSITION_DURATION_MS, () => {
      self.destroy();
    });
  };

  return (
    <window
      {...restProps}
      name="notification"
      setup={(self) => {
        setup?.(self);
        selfRef.set(self);

        childRevealedState.set(true);
        timeout(3500, () => {
          destroySelf(self);
        });
      }}
      anchor={TOP | LEFT | RIGHT}
      application={application}
      cssClasses={["bg-transparent", "min-h-24", "mt-8", "pt-1.5"]}
      exclusivity={Astal.Exclusivity.IGNORE}
      focusable={false}
      keymode={Astal.Keymode.NONE}
      layer={Astal.Layer.TOP}
    >
      <revealer
        halign={Gtk.Align.CENTER}
        hexpand={false}
        valign={Gtk.Align.START}
        vexpand={false}
        revealChild={bind(childRevealedState)}
        transitionDuration={TRANSITION_DURATION_MS}
        transitionType={Gtk.RevealerTransitionType.SLIDE_DOWN}
      >
        {bind(selfRef).as(
          (self) =>
            self && (
              <GtkScrolledWindow
                halign={Gtk.Align.CENTER}
                hexpand={false}
                hscrollbarPolicy={Gtk.PolicyType.NEVER}
                minContentHeight={200}
                overflow={Gtk.Overflow.HIDDEN}
                vscrollbarPolicy={Gtk.PolicyType.EXTERNAL}
              >
                <Notification
                  cssClasses={[
                    "min-w-96",
                    // Margins to prevent shadow clipping.
                    "mx-6",
                    "mb-6",
                    "shadow-xl",
                    "shadow-black",
                  ]}
                  notification={notification}
                  showRelativeTime
                  window={self}
                  onDismissClicked={() => {
                    notification.dismiss();
                    destroySelf(self);
                  }}
                />
              </GtkScrolledWindow>
            )
        )}
      </revealer>
    </window>
  );
};
