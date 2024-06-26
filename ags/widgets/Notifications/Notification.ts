import { type Notification as SystemNotification } from "types/service/notifications";
import GLib from "gi://GLib";

export const Notification = (notification: SystemNotification) => {
  const icon = NotificationIcon(notification);

  const content = Widget.Box({
    class_name: "content",
    children: [
      ...(icon ? [icon] : []),
      Widget.Box({
        hexpand: true,
        vertical: true,
        children: [
          Widget.Box({
            class_name: "header horizontal",
            children: [
              Widget.Label({
                class_name: "title",
                vpack: "center",
                hexpand: true,
                xalign: 0,
                justification: "left",
                max_width_chars: 24,
                truncate: "end",
                wrap: true,
                label: notification.summary.trim(),
                use_markup: true,
              }),
              Widget.Label({
                class_name: "time",
                vpack: "center",
                label: time(notification.time),
              }),
              Widget.Button({
                class_name: "close-button",
                vpack: "start",
                child: Widget.Icon("window-close-symbolic"),
                on_clicked: notification.close,
              }),
            ],
          }),
          ...(notification.body.trim() === ""
            ? []
            : [
                Widget.Label({
                  class_name: "description",
                  hexpand: true,
                  use_markup: true,
                  xalign: 0,
                  justification: "left",
                  label: notification.body.trim(),
                  max_width_chars: 24,
                  wrap: true,
                }),
              ]),
        ],
      }),
    ],
  });

  const actionbox =
    notification.actions.length > 0
      ? Widget.Revealer({
          transition: "slide_down",
          child: Widget.EventBox({
            child: Widget.Box({
              class_name: "actions horizontal",
              children: notification.actions.map((action) =>
                Widget.Button({
                  class_name: "button",
                  on_clicked: () => notification.invoke(action.id),
                  hexpand: true,
                  child: Widget.Label(action.label),
                })
              ),
            }),
          }),
        })
      : null;

  const eventbox = Widget.EventBox({
    vexpand: false,
    on_primary_click: notification.dismiss,
    on_hover() {
      if (actionbox) actionbox.reveal_child = true;
    },
    on_hover_lost() {
      if (actionbox) actionbox.reveal_child = false;
    },
    child: Widget.Box({
      vertical: true,
      children: actionbox ? [content, actionbox] : [content],
    }),
  });

  return Widget.Box({
    class_name: `notification ${notification.urgency}`,
    child: eventbox,
  });
};

const time = (time: number, format = "%H:%M") =>
  GLib.DateTime.new_from_unix_local(time).format(format);

const NotificationIcon = ({
  app_entry,
  app_icon,
  image,
}: SystemNotification) => {
  if (image) {
    return Widget.Box({
      vpack: "start",
      hexpand: false,
      class_name: "icon img",
      css: `
        background-image: url("${image}");
        background-size: cover;
        background-repeat: no-repeat;
        background-position: center;
        min-width: 78px;
        min-height: 78px;
      `,
    });
  }

  let icon: string | undefined = undefined;
  if (Utils.lookUpIcon(app_icon)) icon = app_icon;
  if (Utils.lookUpIcon(app_entry || "")) icon = app_entry || "";

  return icon === undefined
    ? undefined
    : Widget.Box({
        vpack: "start",
        hexpand: false,
        class_name: "icon",
        css: `
          min-width: 78px;
          min-height: 78px;
        `,
        child: Widget.Icon({
          icon,
          size: 58,
          hpack: "center",
          hexpand: true,
          vpack: "center",
          vexpand: true,
        }),
      });
};
