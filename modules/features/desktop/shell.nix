{
  config,
  hmConfig,
  inputs,
  lib,
  osConfig,
  pkgs,
  ...
}: let
  cfg = config.features.desktop;
  adwShellPkg = inputs.adw-shell.packages.${pkgs.stdenv.hostPlatform.system}.default;
  agsPkg = inputs.adw-shell.packages.${pkgs.stdenv.hostPlatform.system}.ags;
  hyprshutdownPkg = inputs.hyprland-hyprshutdown.packages.${pkgs.stdenv.hostPlatform.system}.default;
  hyprshutdown = lib.getExe hyprshutdownPkg;
in {
  config.os = lib.mkIf cfg.enable {
    # Allow the desktop user to shut down and reboot without a password prompt.
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (
          (action.id === "org.freedesktop.login1.power-off" ||
           action.id === "org.freedesktop.login1.reboot") &&
          subject.user === "${hmConfig.home.username}"
        ) {
          return polkit.Result.YES;
        }
      });
    '';
  };

  config.hm = lib.mkIf cfg.enable {
    home.packages = [
      adwShellPkg
      agsPkg
      hyprshutdownPkg
    ];

    xdg.configFile."adw-shell/config.json".text = let
      grimblast = lib.getExe inputs.hyprland-contrib.packages.${pkgs.stdenv.hostPlatform.system}.grimblast;
    in
      builtins.toJSON {
        commands = {
          lock = ["${pkgs.systemd}/bin/loginctl" "lock-session"];
          "log-out" = ["${pkgs.systemd}/bin/systemctl" "--user" "start" "desktop-logout.service"];
          restart = ["${pkgs.systemd}/bin/systemctl" "--user" "start" "desktop-reboot.service"];
          screenshot = [
            "${grimblast}"
            "--notify"
            "--freeze"
            "copy"
            "area"
          ];
          shutdown = ["${pkgs.systemd}/bin/systemctl" "--user" "start" "desktop-shutdown.service"];
          suspend = ["${pkgs.systemd}/bin/systemctl" "suspend"];
        };
      };

    systemd.user.services = {
      adw-shell = {
        Unit = {
          Description = "Adwaita Shell";
          Documentation = "https://github.com/gian-reto/adw-shell";
          PartOf = ["graphical-session.target"];
          After = ["graphical-session-pre.target"];
        };

        Service = {
          ExecStart = "${adwShellPkg}/bin/adw-shell";
          Restart = "on-failure";
          RestartPreventExitStatus = 143;
          RestartSec = 5;
          KillMode = "mixed";
        };

        Install = {
          WantedBy = ["graphical-session.target"];
        };
      };

      desktop-logout = let
        logoutScript = pkgs.writeShellScript "desktop-logout" ''
          ${hyprshutdown} -t "Logging out..." --post-cmd "${lib.getExe osConfig.programs.uwsm.package} stop"
        '';
      in {
        Unit = {
          Description = "Desktop-initiated session logout";
        };

        Service = {
          Type = "oneshot";
          ExecStart = "${logoutScript}";
          KillMode = "none";
        };
      };

      desktop-reboot = let
        rebootScript = pkgs.writeShellScript "desktop-reboot" ''
          ${hyprshutdown} -t "Restarting..." --post-cmd "${pkgs.systemd}/bin/systemctl reboot"
        '';
      in {
        Unit = {
          Description = "Desktop-initiated system reboot";
        };

        Service = {
          Type = "oneshot";
          ExecStart = "${rebootScript}";
          KillMode = "none";
        };
      };

      desktop-shutdown = let
        shutdownScript = pkgs.writeShellScript "desktop-shutdown" ''
          ${hyprshutdown} -t "Shutting down..." --post-cmd "${pkgs.systemd}/bin/systemctl poweroff"
        '';
      in {
        Unit = {
          Description = "Desktop-initiated system shutdown";
        };

        Service = {
          Type = "oneshot";
          ExecStart = "${shutdownScript}";
          KillMode = "none";
        };
      };
    };
  };
}
