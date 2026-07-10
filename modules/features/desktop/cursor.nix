{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf config.features.desktop.enable {
  hm.home.pointerCursor = {
    enable = true;

    gtk.enable = true;
    name = "macOS";
    package = pkgs.apple-cursor;
    size = 24;
    x11 = {
      enable = true;

      defaultCursor = "macOS";
    };
  };
}
