{lib, ...}: let
  # Helper to define a monitor option set.
  mkMonitorOptions = {
    required ? false,
    description ? "",
  }: {
    id = lib.mkOption {
      description = "The id of the ${description} monitor.";
      type =
        if required
        then lib.types.str
        else lib.types.nullOr lib.types.str;
      default =
        if required
        then null
        else null;
      example = "eDP-1";
    };
    width = lib.mkOption {
      description = "The width of the ${description} monitor.";
      type =
        if required
        then lib.types.int
        else lib.types.nullOr lib.types.int;
      default =
        if required
        then null
        else null;
      example = 1920;
    };
    height = lib.mkOption {
      description = "The height of the ${description} monitor.";
      type =
        if required
        then lib.types.int
        else lib.types.nullOr lib.types.int;
      default =
        if required
        then null
        else null;
      example = 1200;
    };
    scale = lib.mkOption {
      description = "The scale of the ${description} monitor.";
      type = lib.types.float;
      default = 1.0;
      example = 1.5;
    };
    refreshRate = lib.mkOption {
      description = "The refresh rate of the ${description} monitor.";
      type = lib.types.oneOf [
        lib.types.float
        lib.types.int
        lib.types.str
      ];
      default = 60;
      example = 144;
    };
    rotation = lib.mkOption {
      description = "The rotation of the ${description} monitor (0, 1, 2, or 3).";
      type = lib.types.int;
      default = 0;
      example = 1;
    };
    position = lib.mkOption {
      description = ''
        The position of the ${description} monitor in the virtual layout.
        Can be "auto" or coordinates like "0x0", "1920x0", etc.
      '';
      type = lib.types.str;
      default = "auto";
      example = "0x0";
    };
  };
in {
  imports = [
    ./cursor.nix
    ./fonts.nix
    ./greeter.nix
    ./hyprland
    ./security.nix
    ./shell.nix
  ];

  options.features.desktop = {
    enable = lib.mkOption {
      description = "Whether to enable the desktop environment.";
      type = lib.types.bool;
      default = false;
      example = true;
    };

    compositor = lib.mkOption {
      description = "The Wayland compositor to use.";
      type = lib.types.enum ["hyprland"];
      default = "hyprland";
      example = "hyprland";
    };

    wallpaper = lib.mkOption {
      description = "Path to the wallpaper image.";
      type = lib.types.path;
      default = ../../../files/wallpaper.jpg;
      example = lib.literalExpression "./wallpaper.jpg";
    };

    monitors = {
      main = mkMonitorOptions {
        required = true;
        description = "main";
      };
      secondary = mkMonitorOptions {description = "secondary";};
      tertiary = mkMonitorOptions {description = "tertiary";};
      quaternary = mkMonitorOptions {description = "quaternary";};
    };
  };
}
