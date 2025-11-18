{
  lib,
  config,
  pkgs,
  ...
}: {
  options.features.security.enable = lib.mkOption {
    description = ''
      Whether to enable secret management and access control features.
    '';
    type = lib.types.bool;
    default = false;
    example = true;
  };

  config.os = lib.mkIf config.features.security.enable {
    environment.variables.XDG_RUNTIME_DIR = "/run/user/$UID";

    programs = {
      seahorse.enable = true;
    };

    services.gnome.gnome-keyring.enable = true;
    security = {
      polkit.enable = true;

      pam.services = {
        login.fprintAuth = false;
        hyprlock = {
          enableGnomeKeyring = true;
          fprintAuth = false;
        };
      };
    };

    systemd = {
      user.services.polkit-gnome-authentication-agent-1 = {
        description = "polkit-gnome-authentication-agent-1";
        wantedBy = ["graphical-session.target"];
        wants = ["graphical-session.target"];
        after = ["graphical-session.target"];
        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
          Restart = "on-failure";
          RestartSec = 1;
          TimeoutStopSec = 10;
        };
      };
    };
  };
}
