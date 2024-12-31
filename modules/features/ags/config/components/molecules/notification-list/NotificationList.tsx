import {
  GtkScrolledWindow,
  GtkScrolledWindowProps,
} from "../../../widgets/GtkScrolledWindow";
import {
  Notification,
  NotificationProps,
} from "../../atoms/notification/Notification";

import { Gtk } from "astal/gtk4";
import Notifd from "gi://AstalNotifd";
import { VariableMap } from "../../../util/variable-map";
import { bind } from "astal";
import { cx } from "../../../util/cx";
import { difference } from "../../../util/array";

const notifd = Notifd.get_default();

export type NotificationListProps = Omit<
  GtkScrolledWindowProps,
  | "cssClasses"
  | "hscrollbarPolicy"
  | "minContentHeight"
  | "overflow"
  | "vscrollbarPolicy"
> &
  Pick<NotificationProps, "window"> & {
    readonly cssClasses?: string[];
  };

export const NotificationList = (props: NotificationListProps): Gtk.Widget => {
  const { cssClasses, window, ...restProps } = props;

  /**
   * A map of notification IDs to their corresponding `Notification` component.
   */
  const currentNotificationComponents = new VariableMap<
    MapKey,
    ReturnType<typeof Notification>
  >(
    // Initialize the map with the current workspaces.
    calculateNotificationChanges(notifd.notifications).addedNotifications.map(
      (notification) => [
        getMapKey(notification),
        <Notification
          notification={notification}
          showRelativeTime
          window={window}
          onDismissClicked={() => notification.dismiss()}
        />,
      ]
    )
  );

  const notificationsUnsubscriber = bind(notifd, "notifications").subscribe(
    (currentNotifications) => {
      const { addedNotifications, removedNotificationIds } =
        calculateNotificationChanges(
          currentNotifications,
          currentNotificationComponents
        );

      for (const notification of addedNotifications) {
        currentNotificationComponents.set(
          getMapKey(notification),
          <Notification
            notification={notification}
            showRelativeTime
            window={window}
            onDismissClicked={() => notification.dismiss()}
          />
        );
      }
      for (const id of removedNotificationIds) {
        currentNotificationComponents.delete(id);
      }
    }
  );

  return (
    <GtkScrolledWindow
      {...restProps}
      cssClasses={cx(cssClasses, "rounded-t-xl")}
      hscrollbarPolicy={Gtk.PolicyType.NEVER}
      minContentHeight={300}
      overflow={Gtk.Overflow.HIDDEN}
      vscrollbarPolicy={Gtk.PolicyType.EXTERNAL}
    >
      <box
        cssClasses={["min-w-96", "pb-3", "space-y-3"]}
        hexpand={false}
        vertical
        onDestroy={notificationsUnsubscriber}
      >
        {bind(currentNotificationComponents).as((notificationComponents) =>
          notificationComponents.length > 0 ? (
            notificationComponents
              .sort(([aKey], [bKey]) => bKey.localeCompare(aKey))
              .map(([, notificationComponent]) => notificationComponent)
          ) : (
            <label
              cssClasses={["text-gray-100", "p-5"]}
              halign={Gtk.Align.CENTER}
              valign={Gtk.Align.CENTER}
              vexpand={false}
            >
              No notifications
            </label>
          )
        )}
      </box>
    </GtkScrolledWindow>
  );
};

type MapKey = string & { readonly __mapKey: unique symbol };

/**
 * Returns a unique key for an item in the notification map, based on the
 * corresponding notification's `id` and `time`. If the notifications are sorted
 * by this key, they will implicitly be sorted by time as well.
 */
const getMapKey = (notification: {
  readonly id: number;
  readonly time: number;
}): MapKey => `${notification.time}-${notification.id}` as MapKey;

/**
 * Get the list of notifications that don't have a corresponding `Notification`
 * component yet, and the list of notification {@link MapKey}s that have a
 * corresponding `Notification` but don't exist anymore.
 */
const calculateNotificationChanges = (
  notifications: Array<Notifd.Notification>,
  notificationComponents?: VariableMap<MapKey, ReturnType<typeof Notification>>
): {
  addedNotifications: Array<Notifd.Notification>;
  removedNotificationIds: Array<MapKey>;
} => {
  if (notificationComponents === undefined) {
    return {
      addedNotifications: notifications,
      removedNotificationIds: [],
    };
  }

  const notificationIds = notifications.map((notification) =>
    getMapKey(notification)
  );
  const notificationComponentIds = notificationComponents
    .get()
    .map(([id]) => id);
  const addedNotificationIds = difference(
    notificationIds,
    notificationComponentIds
  );

  return {
    addedNotifications: notifications.filter((notification) =>
      addedNotificationIds.includes(getMapKey(notification))
    ),
    removedNotificationIds: difference(
      notificationComponentIds,
      notificationIds
    ),
  };
};
