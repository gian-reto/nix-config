{
  config,
  lib,
  osConfig,
  ...
}: {
  options.features.greeter.enable = lib.mkOption {
    description = ''
      Whether to enable the greeter feature (login screen).
    '';
    type = lib.types.bool;
    default = false;
    example = true;
  };

  config.os = lib.mkIf config.features.greeter.enable {
    services.greetd = let
      session = {
        command = "${lib.getExe osConfig.programs.hyprland.package}";
        user = config.hmUsername;
      };
    in {
      enable = true;

      settings = {
        terminal.vt = 1;
        default_session = session;
        initial_session = session;
      };
    };

    # TODO: Probably not needed because of hyprlock, but let's see.
    # lib.mkIf config.features.security.enable {
    #   # Unlock GPG keyring on login.
    #   security.pam.services.greetd.enableGnomeKeyring = true;
    # };
  };
}