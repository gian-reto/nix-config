{
  config,
  lib,
  pkgs,
  ...
}: {
  options.features.cursor.enable = lib.mkOption {
    description = ''
      Whether to enable custom cursors.
      Note: Font families are hardcoded at the moment.
    '';
    type = lib.types.bool;
    default = false;
    example = true;
  };

  config.hm = lib.mkIf config.features.cursor.enable {
    home.pointerCursor = {
      name = "macOS";
      package = pkgs.apple-cursor;
      size = 24;
      gtk.enable = true;
      x11 = {
        enable = true;

        defaultCursor = "macOS";
      };
    };
  };
}
