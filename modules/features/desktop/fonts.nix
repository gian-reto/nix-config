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

      # Prevents emoji fonts from being used for non-emoji characters (e.g.
      # spaces), which can cause issues like wide spaces, e.g. when a CSS
      # font stack names an emoji font before a generic `sans-serif`.
      # Works by prepending Inter weakly before any emoji font, so Inter
      # wins for text codepoints while emoji codepoints fall through to the
      # emoji font.
      localConf = let
        # Emoji font families commonly found in CSS font stacks that should
        # not be used for rendering regular text characters.
        emojiFontFamilies = [
          "Android Emoji"
          "Apple Color Emoji"
          "AppleColorEmoji"
          "Emoji One"
          "Emoji Two"
          "EmojiOne Color"
          "EmojiOne Mozilla"
          "EmojiOne"
          "EmojiSymbols"
          "EmojiTwo"
          "JoyPixels"
          "Noto Color Emoji"
          "Noto Emoji"
          "NotoColorEmoji"
          "Segoe UI Emoji"
          "Segoe UI Symbol"
          "Symbola"
          "Twemoji Mozilla"
          "Twemoji"
          "TwemojiMozilla"
          "Twitter Color Emoji"
        ];

        mkEmojiFontRule = family: ''
          <match target="pattern">
            <test qual="any" name="family">
              <string>${family}</string>
            </test>
            <edit name="family" mode="prepend" binding="weak">
              <string>Inter</string>
            </edit>
          </match>
        '';
      in ''
        <?xml version='1.0'?>
        <!DOCTYPE fontconfig SYSTEM 'fonts.dtd'>
        <fontconfig>
          ${lib.concatMapStrings mkEmojiFontRule emojiFontFamilies}
        </fontconfig>
      '';
    };
  };
}
