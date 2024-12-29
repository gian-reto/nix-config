{
  config,
  lib,
  osConfig,
  ...
}: {
  options.features.alacritty.enable = lib.mkOption {
    description = ''
      Whether to enable Alacritty.
    '';
    type = lib.types.bool;
    default = false;
    example = true;
  };

  config.hm = lib.mkIf config.features.alacritty.enable {
    programs.alacritty = {
      enable = true;

      settings = {
        env.term = "xterm-256color";

        window = {
          padding.x = 10;
          padding.y = 10;
          dynamic_padding = true;
          decorations = "None";
          startup_mode = "Maximized";
          opacity = 0.75;
        };

        font = {
          size = 11.0;

          normal.family = builtins.head osConfig.fonts.fontconfig.defaultFonts.monospace;
        };

        cursor = {
          style = {
            shape = "Beam";
            blinking = "Always";
          };
        };

        colors = {
          primary = {
            background = "0x1e1e1e";
            foreground = "0xffffff";
          };
          normal = {
            black = "0x171421";
            red = "0xc01c28";
            green = "0x26a269";
            yellow = "0xa2734c";
            blue = "0x12488b";
            magenta = "0xa347ba";
            cyan = "0x2aa1b3";
            white = "0xd0cfcc";
          };
          bright = {
            black = "0x5e5c64";
            red = "0xf66151";
            green = "0x33d17a";
            yellow = "0xe9ad0c";
            blue = "0x2a7bde";
            magenta = "0xc061cb";
            cyan = "0x33c7de";
            white = "0xffffff";
          };
        };
      };
    };
  };
}
