{
  lib,
  config,
  pkgs,
  hmConfig,
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
    programs = {
      seahorse.enable = true;
      _1password = {
        enable = true;

        package = pkgs._1password-cli;
      };
      _1password-gui = {
        enable = true;

        package = pkgs._1password-gui;
        polkitPolicyOwners = [hmConfig.home.username];
      };
    };

    services.gnome.gnome-keyring.enable = true;
    security = {
      polkit.enable = true;

      pam.services = {
        hyprlock = {
          text = "auth include login";
          enableGnomeKeyring = true;
        };
        greetd = {enableGnomeKeyring = true;};
        login.enableGnomeKeyring = true;
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

    environment.etc."1password/custom_allowed_browsers" = {
      text = ''
        firefox
      '';
      mode = "0755";
    };
  };

  config.hm = lib.mkIf config.features.security.enable {
    # See: https://developer.1password.com/docs/ssh/agent/config.
    xdg.configFile."1Password/ssh/agent.toml".source = pkgs.writers.writeTOML "agent.toml" {
      ssh-keys = [
        {
          vault = "Development";
        }
      ];
    };
  };
}
