{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf config.features.desktop.enable {
  os.fonts = {
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
}
