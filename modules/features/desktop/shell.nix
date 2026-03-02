{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  cfg = config.features.desktop;
  adwShellPkg = inputs.adw-shell.packages.${pkgs.stdenv.hostPlatform.system}.default;
  agsPkg = inputs.adw-shell.packages.${pkgs.stdenv.hostPlatform.system}.ags;
  hyprshutdownPkg = inputs.hyprland-hyprshutdown.packages.${pkgs.stdenv.hostPlatform.system}.default;
in {
  config.hm = lib.mkIf cfg.enable {
    home.packages = [
      adwShellPkg
      agsPkg
      hyprshutdownPkg
    ];

    xdg.configFile."adw-shell/config.json".text = let
      grimblast = lib.getExe inputs.hyprland-contrib.packages.${pkgs.stdenv.hostPlatform.system}.grimblast;
      hyprshutdown = lib.getExe hyprshutdownPkg;
    in
      builtins.toJSON {
        commands = {
          lock = ["${pkgs.systemd}/bin/loginctl" "lock-session"];
          "log-out" = ["${hyprshutdown}"];
          restart = ["${hyprshutdown}" "-t" "Restarting..." "--post-cmd" "reboot"];
          screenshot = [
            "${grimblast}"
            "--notify"
            "--freeze"
            "copy"
            "area"
          ];
          shutdown = ["${hyprshutdown}" "-t" "Shutting down..." "--post-cmd" "shutdown -P 0"];
          suspend = ["${pkgs.systemd}/bin/systemctl" "suspend"];
        };
      };

    systemd.user.services.adw-shell = {
      Unit = {
        Description = "Adwaita Shell";
        Documentation = "https://github.com/gian-reto/adw-shell";
        PartOf = ["graphical-session.target"];
        After = ["graphical-session-pre.target"];
      };

      Service = {
        ExecStart = "${adwShellPkg}/bin/adw-shell";
        Restart = "on-failure";
        RestartSec = 5;
        KillMode = "mixed";
      };

      Install = {
        WantedBy = ["graphical-session.target"];
      };
    };
  };
}
