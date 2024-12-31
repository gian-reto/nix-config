import { App } from "astal/gtk4";
import Bar from "./components/partials/bar/Bar";
import { ControlCenterPopupWindow } from "./components/partials/control-center-popup-window/ControlCenterPopupWindow";
import { LauncherPopupWindow } from "./components/partials/launcher-popup-window/LauncherPopupWindow";
import Notifd from "gi://AstalNotifd";
import { NotificationCenterPopupWindow } from "./components/partials/notification-center-popup-window/NotificationCenterPopupWindow";
import { NotificationPopupWindow } from "./components/partials/notification-popup-window/NotificationPopupWindow";
import { getStylesheet } from "./theme";

const notifd = Notifd.get_default();

App.start({
  css: getStylesheet("adwaita-dark"),
  main() {
    App.get_monitors().map((monitor) =>
      Bar({
        application: App,
        gdkmonitor: monitor,
      })
    );
    ControlCenterPopupWindow({
      application: App,
      visible: false,
    });
    LauncherPopupWindow({
      application: App,
      visible: false,
    });
    NotificationCenterPopupWindow({
      application: App,
      visible: false,
    });

    notifd.connect("notified", (self, id) => {
      if (self.get_dont_disturb() === true) return;

      const notification = notifd.get_notification(id);

      if (notification) {
        NotificationPopupWindow({
          application: App,
          notification,
          visible: true,
        });
      }
    });
  },
  requestHandler(request, res) {
    if (request === "toggle-launcher") {
      App.toggle_window("launcher");
    }
  },
});
