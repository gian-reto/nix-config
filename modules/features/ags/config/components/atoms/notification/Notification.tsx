import { GLib, Gio, Variable, bind } from "astal";

import Apps from "gi://AstalApps";
import { BoxProps } from "astal/gtk4/widget";
import { Gtk } from "astal/gtk4";
import Notifd from "gi://AstalNotifd";
import Pango from "gi://Pango?version=1.0";
import { cx } from "../../../util/cx";
import { isPathOfValidImage } from "../../../util/path";
import { lookUpIcon } from "../../../util/icon";

const apps = new Apps.Apps({
  minScore: 1,
  nameMultiplier: 1,
});

const currentDateTimeState = Variable("").poll(
  1000 * 60,
  'date --iso-8601="minutes"'
);

export type NotificationProps = Omit<BoxProps, "cssClasses"> & {
  readonly cssClasses?: string[];
  readonly notification: Notifd.Notification;
  /**
   * Whether to show the relative time of the notification (in addition to the
   * timestamp). Defaults to `true`.
   */
  readonly showRelativeTime?: boolean;
  /**
   * Reference of the parent window.
   */
  readonly window: Gtk.Window;
  /**
   * Function called when the user clicks the dismiss button.
   */
  readonly onDismissClicked?: () => void;
};

export const Notification = (props: NotificationProps): Gtk.Widget => {
  const {
    cssClasses,
    notification,
    onDismissClicked,
    setup,
    showRelativeTime = true,
    window,
    ...restProps
  } = props;
  const { appName, body, time, summary } = props.notification;
  const text = body.trim() === "" ? undefined : body.trim();
  const title = summary.trim() === "" ? appName.trim() : summary.trim();

  const isHoveringState = Variable(false);

  const motion = new Gtk.EventControllerMotion();
  motion.connect("enter", (source) => {
    isHoveringState.set(true);
  });
  motion.connect("leave", (source) => {
    isHoveringState.set(false);
  });

  const notificationImageFile = getNotificationImage(notification);
  const notificationIconPaintable = getNotificationIcon(
    notification,
    window,
    32
  );

  return (
    <box
      {...restProps}
      setup={(self) => {
        setup?.(self);
        self.add_controller(motion);
      }}
      cssClasses={cx(
        cssClasses,
        "bg-gray-400",
        "duration-100",
        "pt-2.5",
        "rounded-xl",
        "shadow-sm"
      )}
      hexpand
      overflow={Gtk.Overflow.HIDDEN}
      valign={Gtk.Align.START}
      vexpand={false}
      vertical
      onButtonPressed={() => {
        if (appName === "") return;

        // If the notification has a single, unlabeled action, invoke it. Note:
        // This condition will only be respected in the first minute after the
        // notification was created, as the actions will likely be unavailable
        // after that time.
        if (
          notification.actions.length === 1 &&
          notification.actions[0].label === "" &&
          GLib.DateTime.new_now_local().difference(
            GLib.DateTime.new_from_unix_local(time)
          ) <
            60 * 1_000_000
        ) {
          notification.invoke(notification.actions[0].id);
          return;
        }

        // In all other cases, find the app by name and launch it if possible.
        const app = apps.exact_query(appName).at(0);
        if (app) {
          app.launch();
        }
      }}
    >
      <box
        cssClasses={["pl-4", "pb-3", "pr-2.5", "space-x-2.5"]}
        vexpand={false}
      >
        {notificationImageFile || notificationIconPaintable ? (
          <image
            cssClasses={["min-w-8", "min-h-8", "pt-1"]}
            file={notificationImageFile?.get_path() ?? undefined}
            halign={Gtk.Align.START}
            hexpand={false}
            paintable={notificationIconPaintable}
            valign={Gtk.Align.START}
            vexpand={false}
          />
        ) : null}
        <box
          cssClasses={["space-y-1"]}
          halign={Gtk.Align.FILL}
          hexpand
          valign={Gtk.Align.START}
          vexpand={false}
          vertical
        >
          <box
            cssClasses={["space-x-2"]}
            halign={Gtk.Align.FILL}
            hexpand
            valign={Gtk.Align.START}
            vexpand={false}
          >
            <label
              cssClasses={["font-semibold", "text-white"]}
              ellipsize={Pango.EllipsizeMode.END}
              halign={Gtk.Align.START}
              justify={Gtk.Justification.LEFT}
              lines={1}
              valign={Gtk.Align.CENTER}
              vexpand={false}
            >
              {title}
            </label>
            <label
              cssClasses={["text-xs", "text-gray-100"]}
              halign={Gtk.Align.START}
              hexpand
              justify={Gtk.Justification.LEFT}
              valign={Gtk.Align.CENTER}
              vexpand={false}
            >
              {bind(currentDateTimeState).as(() =>
                showRelativeTime
                  ? `${formatTime(time)} (${formatTimeRelative(time)})`
                  : formatTime(time)
              )}
            </label>
            <button
              cssClasses={bind(isHoveringState).as((isHovering) =>
                cx(
                  "min-h-5",
                  "min-w-5",
                  isHovering ? "opacity-100" : "opacity-0",
                  "p-px",
                  "rounded-full",
                  "transition-opacity"
                )
              )}
              halign={Gtk.Align.END}
              hexpand={false}
              valign={Gtk.Align.CENTER}
              vexpand={false}
              onClicked={() => {
                onDismissClicked?.();
              }}
            >
              <image
                cssClasses={["text-md"]}
                iconName={"window-close-symbolic"}
              />
            </button>
          </box>
          {text && (
            <label
              cssClasses={["pr-1.5", "text-md", "text-gray-50"]}
              ellipsize={Pango.EllipsizeMode.END}
              halign={Gtk.Align.START}
              hexpand
              justify={Gtk.Justification.LEFT}
              lines={2}
              useMarkup
              valign={Gtk.Align.START}
              vexpand={false}
              wrap
              xalign={0}
              yalign={0}
            >
              {text}
            </label>
          )}
        </box>
      </box>
      {notification.actions.length > 0 &&
        // If the notification has a single, unlabeled action, don't show it.
        !(
          notification.actions.length === 1 &&
          notification.actions[0].label === ""
        ) && (
          <box
            cssClasses={["divide-x", "divide-gray-200"]}
            halign={Gtk.Align.FILL}
            hexpand
            homogeneous
            valign={Gtk.Align.END}
            vexpand={false}
          >
            {notification.actions
              .filter((action) => action.label !== "")
              .map(({ id, label }) => (
                <box
                  cssClasses={[
                    "bg-gray-300",
                    "px-3",
                    "py-3",
                    "rounded-none",
                    "text-white",
                    "transition-colors",
                    "hover:bg-gray-200",
                  ]}
                  halign={Gtk.Align.FILL}
                  hexpand
                  valign={Gtk.Align.CENTER}
                  vexpand={false}
                  onButtonPressed={() => {
                    notification.invoke(id);
                  }}
                >
                  <label
                    cssClasses={["font-semibold", "text-sm", "text-white"]}
                    ellipsize={Pango.EllipsizeMode.END}
                    halign={Gtk.Align.CENTER}
                    hexpand
                    maxWidthChars={30 / notification.actions.length}
                    valign={Gtk.Align.CENTER}
                    vexpand={false}
                    wrap={false}
                  >
                    {label}
                  </label>
                </box>
              ))}
          </box>
        )}
    </box>
  );
};

const formatTime = (time: number, format = "%H:%M"): string | null =>
  GLib.DateTime.new_from_unix_local(time).format(format);

const formatTimeRelative = (time: number): string => {
  const now = GLib.DateTime.new_now_local();
  const then = GLib.DateTime.new_from_unix_local(time);

  // Convert microseconds to seconds.
  const diff = now.difference(then) / 1_000_000;

  if (diff < 60) {
    return "Just now";
  }

  if (diff < 120) {
    return "1 minute ago";
  }

  if (diff < 3600) {
    return `${Math.floor(diff / 60)} minutes ago`;
  }

  if (diff < 7200) {
    return "1 hour ago";
  }

  if (diff < 86400) {
    return `${Math.floor(diff / 3600)} hours ago`;
  }

  if (diff < 172800) {
    return "1 day ago";
  }

  return `${Math.floor(diff / 86400)} days ago`;
};

/**
 * Returns the notification's image or app icon as a {@link Gio.File}, if it
 * exists and is a valid image file. Otherwise, returns `undefined`.
 *
 * Note: If the notification only contains icon names, this function will return
 * `undefined` as well, as it only looks for valid image paths.
 */
const getNotificationImage = (
  notification: Notifd.Notification
): Gio.File | undefined => {
  const { appIcon, image } = notification;

  if (
    !notificationHasAppIcon(notification) &&
    !notificationHasImage(notification)
  ) {
    return undefined;
  }
  if (isPathOfValidImage(appIcon)) {
    return Gio.File.new_for_path(appIcon);
  }
  if (isPathOfValidImage(image)) {
    return Gio.File.new_for_path(image);
  }

  return undefined;
};

/**
 * Returns the notification's app icon as a {@link Gtk.IconPaintable}, if it
 * exists and is a valid icon name. Otherwise, returns `undefined`.
 *
 * Note: If the notification only contains image paths, this function will
 * return `undefined` as well, as it only looks for valid icon names.
 */
const getNotificationIcon = (
  notification: Notifd.Notification,
  window: Gtk.Window,
  size: number
): Gtk.IconPaintable | undefined => {
  const { appIcon, appName } = notification;

  const iconName = notificationHasAppIcon(notification)
    ? appIcon
    : apps.exact_query(appName).at(0)?.iconName;

  if (iconName === undefined) {
    return undefined;
  }
  // Only return a paintable if the icon is NOT a valid image path (because if
  // that would be the case, `getNotificationImage` should be used instead).
  if (isPathOfValidImage(iconName)) {
    return undefined;
  }

  return lookUpIcon(iconName, window.get_scale_factor(), size);
};

const notificationHasAppIcon = (notification: Notifd.Notification) =>
  notification.appIcon && notification.appIcon.length > 0;

const notificationHasImage = (notification: Notifd.Notification) =>
  notification.image && notification.image.length > 0;
