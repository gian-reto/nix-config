{
  config,
  inputs,
  lib,
  osConfig,
  pkgs,
  ...
}: {
  options.features.ghostty.enable = lib.mkOption {
    description = ''
      Whether to enable Ghostty.
    '';
    type = lib.types.bool;
    default = false;
    example = true;
  };

  config.hmModules = lib.mkIf config.features.ghostty.enable [
    inputs.ghostty-hm-module.homeModules.default
  ];

  config.hm = lib.mkIf config.features.ghostty.enable {
    programs.ghostty = {
      enable = true;

      package = inputs.ghostty.packages.${pkgs.system}.default;
      shellIntegration.enable = true;
      settings = {
        # Misc. settings.
        auto-update = "off";

        # Font settings.
        font-family = builtins.head osConfig.fonts.fontconfig.defaultFonts.monospace;
        font-style-bold = false;
        font-style-italic = false;
        font-style-bold-italic = false;
        # Disable ligatures.
        font-feature = ["-calt" "-dlig" "-liga"];
        font-size = 11;

        # Cursor settings.
        cursor-style = "bar";

        # Color settings.
        theme = "Adwaita Dark";
        background-opacity = 0.75;

        # GTK settings.
        gtk-adwaita = true;
      };
    };
  };
}