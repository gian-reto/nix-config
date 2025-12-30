{
  config,
  lib,
  ...
}: let
  cfg = config.features.desktop;
in {
  config.hm = lib.mkIf (cfg.enable && cfg.compositor == "hyprland") {
    xdg.configFile."hypr/hyprpaper.conf".text = ''
      splash = false

      wallpaper {
        monitor =
        path = ${cfg.wallpaper}
        fit_mode = cover
      }
    '';
  };
}
