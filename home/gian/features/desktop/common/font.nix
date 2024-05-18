{
  config,
  pkgs, 
  ...
}: {
  fontProfiles = {
    enable = true;
    monospace = {
      family = "MonaspiceNe NFM";
      package = pkgs.nerdfonts.override { fonts = [ "Monaspace" ]; };
    };
    regular = {
      family = "Inter";
      package = pkgs.inter;
    };
    emoji = {
      family = "Apple Color Emoji";
      package = pkgs.apple-color-emoji;
    };
  };

  fonts.fontconfig = {
    enable = true;
    defaultFonts = {
      sansSerif = [ config.fontProfiles.regular.family ];
      monospace = [ config.fontProfiles.monospace.family ];
      emoji = [ config.fontProfiles.emoji.family ];
    };
  };
}