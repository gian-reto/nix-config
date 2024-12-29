{
  config,
  lib,
  ...
}: {
  options.features.btop.enable = lib.mkOption {
    description = ''
      Whether to enable [btop](https://github.com/aristocratos/btop).
    '';
    type = lib.types.bool;
    default = false;
    example = true;
  };

  config.hm = lib.mkIf config.features.btop.enable {
    programs.btop = {
      enable = true;

      settings = {
        color_theme = "TTY";
        theme_background = false;
      };
    };
  };
}
