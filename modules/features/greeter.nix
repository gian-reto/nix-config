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
  };
}