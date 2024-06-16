import { assetPaths } from "assets";

export const SystemButton = () => {
  const window = "quicksettings";

  return Widget.Button({
    class_name: "system-button section",
    child: Widget.Icon({
      class_name: "icon",
      icon: assetPaths.icons["nix-snowflake-symbolic"],
    }),
    on_clicked: () => App.toggleWindow("quicksettings"),
    setup: (self) => {
      let open = false;

      self.hook(App, (_, win, visible) => {
        if (win !== window) return;

        if (open && !visible) {
          open = false;
          self.toggleClassName("active", false);
        }

        if (visible) {
          open = true;
          self.toggleClassName("active");
        }
      });
    },
  });
};
