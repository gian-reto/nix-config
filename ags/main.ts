import { Bar } from "widgets/Bar/index";
import { setupQuickSettings } from "widgets/QuickSettings/index";

App.config({
  onConfigParsed: () => {
    setupQuickSettings();
  },
  closeWindowDelay: {
    quicksettings: 200,
  },
  windows: [
    Bar(),
    // AppLauncher,
    // NotificationPopups(),
  ],
});
