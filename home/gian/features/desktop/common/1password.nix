{ 
  config, 
  lib, 
  pkgs, 
  ... 
}: {
  systemd.user.services._1password = {
    Unit = {
      Description = "Autostart 1password";
      After = ["graphical-session.target"];
      PartOf = ["graphical-session.target"];
    };
    Install = {
      WantedBy = ["graphical-session.target"];
    };
    Service = {
      Environment = [
        "ELECTRON_OZONE_PLATFORM_HINT=wayland"
        "HOME=${config.home.homeDirectory}"
        "LANG=en_US.UTF-8"
        "LC_ALL=en_US.UTF-8"
      ];
      ExecStart = "${pkgs._1password-gui.override { polkitPolicyOwners = ["gian"]; }}/bin/1password --silent --ozone-platform-hint=wayland";
      Restart = "always";
    };
  };

  # See: https://developer.1password.com/docs/ssh/agent/config.
  xdg.configFile."1Password/ssh/agent.toml".source = pkgs.writers.writeTOML "agent.toml" {
    ssh-keys = [
      {
        vault = "Development";
      }
    ];
  };

  # TODO: Set up impermanence.
  # home.persistence = {
  #   "/persist/home/gian" = {
  #     directories = [
  #       ".config/1Password"
  #     ];
  #   };
  # };
}