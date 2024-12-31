import { App } from "astal/gtk4";
// import style from "./style.scss"
import Bar from "./widget/Bar";
import { NotificationCenterPopupWindow } from "./components/partials/notification-center-popup-window/NotificationCenterPopupWindow";
import { getStylesheet } from "./theme";

App.start({
  css: getStylesheet("adwaita-dark"),
  main() {
    App.get_monitors().map(Bar);
    NotificationCenterPopupWindow({
      application: App,
      visible: false,
    });
  },
});
