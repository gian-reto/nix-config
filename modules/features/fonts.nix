{
  config,
  lib,
  pkgs,
  ...
}: {
  options.features.fonts.enable = lib.mkOption {
    description = ''
      Whether to enable custom fonts.
      Note: Font families are hardcoded at the moment.
    '';
    type = lib.types.bool;
    default = false;
    example = true;
  };

  config.os = lib.mkIf config.features.fonts.enable {
    fonts = {
      packages = with pkgs; [
        apple-color-emoji
        apple-fonts
        blink-mac-system-fonts
        inter
        nerd-fonts.monaspace
        source-serif
      ];

      enableDefaultPackages = false;

      fontconfig = {
        enable = true;

        # Uses `https://github.com/aliifam/BlinkMacSystemFont` to improve
        # weirdness with font stacks that include Apple Color Emoji before
        # default `sans-serif` fonts.
        defaultFonts = {
          serif = ["Source Serif"];
          sansSerif = [
            "Inter"
            "BlinkMacSystemFont"
          ];
          monospace = ["MonaspiceNe NFM"];
          emoji = ["Apple Color Emoji"];
        };
      };
    };
  };
}
