{
  config,
  lib,
  ...
}: {
  options.features.bat.enable = lib.mkOption {
    description = ''
      Whether to enable [bat](https://github.com/sharkdp/bat).
    '';
    type = lib.types.bool;
    default = false;
    example = true;
  };

  config.hm = lib.mkIf config.features.bat.enable {
    programs.bat = {
      enable = true;
      
      config.theme = "base16";
    };
  };
}