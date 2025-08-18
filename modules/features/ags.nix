{
  pkgs,
  config,
  lib,
  inputs,
  ...
}: {
  options.features.ags.enable = lib.mkOption {
    description = ''
      Whether to enable [ags](https://github.com/Aylur/ags) with the
      [adw-shell](https://gian-reto/adw-shell) configuration.
    '';
    type = lib.types.bool;
    default = false;
    example = true;
  };

  config.hm = lib.mkIf config.features.ags.enable {
    home.packages = [
      inputs.adw-shell.packages.${pkgs.system}.default
      inputs.adw-shell.packages.${pkgs.system}.ags
    ];

    systemd.user.services.adw-shell = {
      Unit = {
        Description = "Adwaita Shell";
        PartOf = ["graphical-session.target"];
        After = ["graphical-session-pre.target"];
        Requisite = ["graphical-session.target"];
      };

      Service = {
        ExecStart = "${inputs.adw-shell.packages.${pkgs.system}.default}/bin/adw-shell";
        Restart = "on-failure";
        RestartSec = 3;
        KillMode = "mixed";
      };

      Install = {
        WantedBy = ["graphical-session.target"];
      };
    };
  };
}
