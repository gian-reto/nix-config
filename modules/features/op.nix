{
  lib,
  config,
  pkgs,
  hmConfig,
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
  };
}
