{
  config,
  lib,
  osConfig,
  ...
}: let
  cfg = config.features.desktop;
in {
  config.os = lib.mkIf cfg.enable {
    services.greetd = let
      session = {
        command = "${lib.getExe osConfig.programs.uwsm.package} start ${cfg.compositor}-uwsm.desktop";
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
