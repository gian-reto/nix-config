{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}: {
  options.features.bluetooth.enable = lib.mkOption {
    description = ''
      Whether to enable bluetooth stuff.
    '';
    type = lib.types.bool;
    default = false;
    example = true;
  };

  config.os = lib.mkIf config.features.bluetooth.enable {
    hardware.bluetooth = {
      enable = true;

      powerOnBoot = true;
      settings = {
        General = {
          # Necessary for AirPods.
          ControllerMode = "dual";
          # For `gnome-bluetooth` percentage (useful for `ags`).
          Experimental = "true";
        };
      };
    };

    # ConfigurationDirectory 'bluetooth' already exists but the mode is
    # different. (File system: 755 ConfigurationDirectoryMode: 555).
    systemd.services.bluetooth.serviceConfig.ConfigurationDirectoryMode = "0755";

    services.blueman.enable = true;
  };

  config.hm = lib.mkIf (config.features.bluetooth.enable && config.features.desktop.enable) {
    # Autostart blueman-applet in desktop environments.
    systemd.user.services."autostart-blueman-applet" = {
      Unit = {
        Description = "Blueman Applet";
        PartOf = ["graphical-session.target"];
        After = ["graphical-session.target" "adw-shell.service"];
        Wants = ["graphical-session.target" "adw-shell.service"];
      };

      Service = {
        Type = "simple";
        # Wait for StatusNotifierWatcher to be available on D-Bus before starting.
        ExecStartPre = "${lib.getExe pkgs.bash} -c 'until ${lib.getExe' pkgs.systemd "busctl"} --user list | ${lib.getExe pkgs.gnugrep} -q org.kde.StatusNotifierWatcher; do sleep 1; done'";
        ExecStart = "${lib.getExe osConfig.programs.uwsm.package} app -- ${lib.getExe' pkgs.blueman "blueman-applet"}";
        Restart = "on-failure";
        RestartSec = 5;
      };

      Install = {
        WantedBy = ["graphical-session.target"];
      };
    };
  };
}
