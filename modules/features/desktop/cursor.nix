{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf config.features.desktop.enable {
  hm.home.pointerCursor = {
    name = "macOS";
    package = pkgs.apple-cursor;
    size = 24;
    gtk.enable = true;
    x11 = {
      enable = true;

      defaultCursor = "macOS";
    };
  };
}
