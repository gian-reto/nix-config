{
  lib,
  ...
}: {
  options = {
    theme = {
      wallpaper = lib.mkOption {
        type = lib.types.path;
        description = ''
          The path to the desktop wallpaper image.
        '';
      };
    };
  };
}