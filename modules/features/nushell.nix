{
  config,
  lib,
  ...
}: {
  options.features.nushell.enable = lib.mkOption {
    description = ''
      Whether to enable Nushell.
    '';
    type = lib.types.bool;
    default = false;
    example = true;
  };

  config.hm = lib.mkIf config.features.nushell.enable {
    programs.nushell.enable = true;
  };
}
