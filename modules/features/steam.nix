{
  config,
  lib,
  ...
}: {
  options.features.steam.enable = lib.mkOption {
    description = ''
      Whether to enable Steam.
    '';
    type = lib.types.bool;
    default = false;
    example = true;
  };

  config.os = lib.mkIf config.features.steam.enable {
    programs.steam.enable = true;
  };
}
