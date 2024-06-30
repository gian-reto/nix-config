{
  config,
  lib,
  ...
}: {
  options.features.fastfetch.enable = lib.mkOption {
    description = ''
      Whether to enable fastfetch.
    '';
    type = lib.types.bool;
    default = false;
    example = true;
  };

  config.hm = lib.mkIf config.features.fastfetch.enable {
    programs.fastfetch = {
      enable = true;

      # TODO: Add some settings if needed.
    };
  };
}