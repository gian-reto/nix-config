{
  config,
  lib,
  osConfig,
  ...
}: let
  cfg = config.features.desktop;
in {
  config.hm = lib.mkIf (cfg.enable && cfg.compositor == "hyprland") {
    programs.hyprlock = {
      enable = true;

      settings = {
        general = {
          disable_loading_bar = true;
          hide_cursor = false;
          no_fade_in = true;
        };

        background = [
          {
            monitor = "";
            path = "${cfg.wallpaper}";
          }
        ];

        input-field = [
          {
            monitor = cfg.monitors.main.id;

            size = "300, 50";

            outline_thickness = 0;

            inner_color = "rgb(36, 36, 36)";
            check_color = "rgb(36, 36, 36)";
            font_color = "rgb(255, 255, 255)";
            fail_color = "rgb(224, 27, 36)";

            placeholder_text = ''<span font_family="${builtins.head osConfig.fonts.fontconfig.defaultFonts.sansSerif}">Password...</span>'';

            dots_spacing = 0.2;
            dots_center = true;
          }
        ];

        label = [
          {
            monitor = "";
            text = "$TIME";
            font_family = builtins.head osConfig.fonts.fontconfig.defaultFonts.monospace;
            font_size = 50;
            color = "rgb(255, 255, 255)";

            position = "0, 80";

            valign = "center";
            halign = "center";
          }
        ];
      };
    };
  };
}
