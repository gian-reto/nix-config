import { Notification } from "./Notification";

const notifications = await Service.import("notifications");
const { timeout, idle } = Utils;

const TRANSITION_DURATION_MS = 200;

/**
 * Container widget for notifications.
 */
export const Notifications = (monitor: number) => {
  return Widget.Window({
    name: `notifications-${monitor}`,
    class_name: "notifications",
    monitor,
    anchor: ["top", "right"],
    child: Widget.Box({
      css: "padding: 2px;",
      child: NotificationList(),
    }),
  });
};

const NotificationList = () => {
  const map: Map<
    number,
    ReturnType<typeof getAnimatedNotificationWidget>
  > = new Map();
  const box = Widget.Box({
    class_name: "list",
    hpack: "end",
    vertical: true,
  });

  const remove = (_: unknown, id: number) => {
    map.get(id)?.dismiss();
    map.delete(id);
  };

  return box
    .hook(
      notifications,
      (_, id: number) => {
        if (id !== undefined) {
          if (map.has(id)) remove(null, id);
          if (notifications.dnd) return;

          const notificationWidget = getAnimatedNotificationWidget(id);
          if (!notificationWidget) return;

          map.set(id, notificationWidget);
          box.children = [notificationWidget, ...box.children];
        }
      },
      "notified"
    )
    .hook(notifications, remove, "dismissed")
    .hook(notifications, remove, "closed");
};

const getAnimatedNotificationWidget = (id: number) => {
  const notification = notifications.getNotification(id);
  if (!notification) return;

  const notificationWidget = Notification(notification);

  const inner = Widget.Revealer({
    transition: "slide_left",
    transition_duration: TRANSITION_DURATION_MS,
    child: notificationWidget,
  });

  const outer = Widget.Revealer({
    transition: "slide_down",
    transition_duration: TRANSITION_DURATION_MS,
    child: inner,
  });

  const box = Widget.Box({
    hpack: "end",
    child: outer,
  });

  idle(() => {
    outer.reveal_child = true;
    timeout(TRANSITION_DURATION_MS, () => {
      inner.reveal_child = true;
    });
  });

  return Object.assign(box, {
    dismiss() {
      inner.reveal_child = false;
      timeout(TRANSITION_DURATION_MS, () => {
        outer.reveal_child = false;
        timeout(TRANSITION_DURATION_MS, () => {
          box.destroy();
        });
      });
    },
  });
};
