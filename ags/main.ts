import { Bar } from "widgets/Bar/index";
import { Notifications } from "widgets/Notifications/index";
import { forMonitors } from "lib/utils";
import { initNotificationService } from "lib/notifications";
import { setupQuickSettings } from "widgets/QuickSettings/index";

const init = () => {
  try {
    initNotificationService();
  } catch (error) {
    logError(error);
  }
};

App.config({
  onConfigParsed: () => {
    setupQuickSettings();
    init();
  },
  closeWindowDelay: {
    quicksettings: 150,
  },
  windows: [
    ...forMonitors(Notifications),
    ...forMonitors(Bar),
    // Launcher()
  ],
});
