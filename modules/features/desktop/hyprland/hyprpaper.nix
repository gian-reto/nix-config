{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  cfg = config.features.desktop;
in {
  config.hm = lib.mkIf (cfg.enable && cfg.compositor == "hyprland") {
    home.packages = [
      inputs.hyprland-hyprpaper.packages.${pkgs.stdenv.hostPlatform.system}.hyprpaper
    ];

    xdg.configFile."hypr/hyprpaper.conf".text = ''
      splash = false

      wallpaper {
        monitor =
        path = ${cfg.wallpaper}
        fit_mode = cover
      }
    '';

    systemd.user.targets.graphical-session = {
      Unit.Wants = ["hyprpaper.service"];
    };
  };
}
