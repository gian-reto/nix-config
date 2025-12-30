{
  lib,
  config,
  hmConfig,
  osConfig,
  pkgs,
  ...
}: {
  options.features.op.enable = lib.mkOption {
    description = ''
      Whether to enable 1password.
    '';
    type = lib.types.bool;
    default = false;
    example = true;
  };

  config.os = lib.mkIf config.features.op.enable {
    programs = {
      _1password = {
        enable = true;

        package = pkgs._1password-cli;
      };
      _1password-gui = {
        enable = true;

        package = pkgs._1password-gui-beta;
        polkitPolicyOwners = [hmConfig.home.username];
      };
    };

    environment.etc."1password/custom_allowed_browsers" = {
      mode = "0755";
      text = lib.concatLines ([]
        ++ lib.optionals config.features.firefox.enable [
          "firefox"
          "firefox-devedition"
        ]);
    };
  };

  config.hm = lib.mkIf config.features.op.enable {
    # See: https://developer.1password.com/docs/ssh/agent/config.
    xdg.configFile."1Password/ssh/agent.toml".source = pkgs.writers.writeTOML "agent.toml" {
      ssh-keys = [
        {
          vault = "Development";
        }
      ];
    };

    # Autostart 1Password in desktop environments.
    systemd.user.services."autostart-onepassword" = lib.mkIf config.features.desktop.enable {
      Unit = {
        Description = "1Password GUI";
        PartOf = ["graphical-session.target"];
        After = ["graphical-session.target" "adw-shell.service"];
        Wants = ["graphical-session.target" "adw-shell.service"];
      };

      Service = {
        Type = "simple";
        # Wait for StatusNotifierWatcher to be available on D-Bus before starting.
        ExecStartPre = "${lib.getExe pkgs.bash} -c 'until ${lib.getExe' pkgs.systemd "busctl"} --user list | ${lib.getExe pkgs.gnugrep} -q org.kde.StatusNotifierWatcher; do sleep 1; done'";
        ExecStart = "${lib.getExe osConfig.programs.uwsm.package} app -- ${lib.getExe' pkgs._1password-gui-beta "1password"} --silent --ozone-platform-hint=auto";
        Restart = "on-failure";
        RestartSec = 5;
      };

      Install = {
        WantedBy = ["graphical-session.target"];
      };
    };
  };
}
