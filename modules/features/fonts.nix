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
        inter
        (nerdfonts.override { fonts = [ "Monaspace" ]; })
      ];

      enableDefaultPackages = false;

      fontconfig = {
        enable = true;
        
        defaultFonts = {
          serif = [ "New York" ];
          sansSerif = [ "Inter" ];
          monospace = [ "MonaspiceNe NFM" ];
          emoji = [ "Apple Color Emoji" ];
        };
      };
    };
  };
}