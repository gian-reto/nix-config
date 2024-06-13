{
  config,
  lib,
  ...
}: {
  options.features.bash.enable = lib.mkOption {
    description = ''
      Whether to enable bash. 
    '';
    type = lib.types.bool;
    default = false;
    example = true;
  };

  config.hm = lib.mkIf config.features.bash.enable {
    programs.bash = {
      enable = true;
    };
  };
}