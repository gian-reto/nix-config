{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  zen-browser = inputs.zen-browser.packages.${pkgs.system}.default;
in {
  options.features.zen-browser.enable = lib.mkOption {
    description = ''
      Whether to enable Zen Browser.
    '';
    type = lib.types.bool;
    default = false;
    example = true;
  };

  config.hm = lib.mkIf config.features.zen-browser.enable {
    home.packages = [
      zen-browser
    ];

    home.sessionVariables = {
      BROWSER = "x-www-browser";
      MOZ_ENABLE_WAYLAND = 1;
      MOZ_LEGACY_PROFILES = 1;
    };

    xdg.mimeApps.defaultApplications = {
      "applications/x-www-browser" = ["zen.desktop"];
      "text/html" = ["zen.desktop"];
      "text/xml" = ["zen.desktop"];
      "x-scheme-handler/about" = ["zen.desktop"];
      "x-scheme-handler/http" = ["zen.desktop"];
      "x-scheme-handler/https" = ["zen.desktop"];
    };
  };
}
