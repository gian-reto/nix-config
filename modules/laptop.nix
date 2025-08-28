{
  lib,
  config,
  ...
}: {
  options.laptop.enable = lib.mkOption {
    description = ''
      Whether to enable features specific to laptops.
    '';
    type = lib.types.bool;
    default = false;
    example = true;
  };

  config = lib.mkIf config.laptop.enable {
    # Currently empty.
  };
}
