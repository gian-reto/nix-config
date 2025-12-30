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
in {
  config.hm = lib.mkIf cfg.enable {
    home.packages = [
      adwShellPkg
      agsPkg
    ];

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
