{
  config,
  lib,
  pkgs,
  ...
}: {
  options.features.hypridle.enable = lib.mkOption {
    description = ''
      Whether to enable `hypridle`.
    '';
    type = lib.types.bool;
    default = false;
    example = true;
  };

  config.hm = lib.mkIf config.features.hypridle.enable {
    services.hypridle = {
      enable = true;

      settings = {
        general = {
          lock_cmd = "pidof hyprlock || hyprlock";
          before_sleep_cmd = "loginctl lock-session";
          after_sleep_cmd = "hyprctl dispatch dpms on";
        };

        listener = [
          {
            timeout = 570; # 9 minutes and 30 seconds.
            on-timeout = "${pkgs.libnotify}/bin/notify-send 'Locking in 30 seconds' -t 30000";
          }
          {
            timeout = 600; # 10 minutes.
            on-timeout = "loginctl lock-session";
          }
          {
            timeout = 780; # 13 minutes.
            on-timeout = "hyprctl dispatch dpms off";
            on-resume = "hyprctl dispatch dpms on";
          }
          {
            timeout = 900; # 15 minutes.
            on-timeout = "systemctl suspend-then-hibernate";
          }
        ];
      };
    };
  };
}
