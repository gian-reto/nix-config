# Module for laptop features.
{
  config,
  lib,
  ...
}: {
  options.laptop.enable = lib.mkOption {
    description = ''
      Whether to enable laptop features.
    '';
    type = lib.types.bool;
    default = false;
    example = true;
  };

  config = lib.mkIf config.laptop.enable {
    features.tlp.enable = true;
  };
}
