{
  config,
  lib,
  pkgs,
  ...
}: {
  options.features.tlp.enable = lib.mkOption {
    description = ''
      Whether to enable tlp (energy management).
    '';
    type = lib.types.bool;
    default = false;
    example = true;
  };

  config.os = lib.mkIf config.features.tlp.enable {
    services.tlp.enable = true;
  };
}