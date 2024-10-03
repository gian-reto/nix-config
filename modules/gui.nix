# Module for enabling desktop environment / GUI features.
{
  config,
  lib,
  pkgs,
  ...
}: {
  options = {
    gui = {
      enable = lib.mkOption {
        description = ''
          Whether to enable a desktop environment and some GUI applications.
        '';
        type = lib.types.bool;
        default = false;
        example = true;
      };
      environment = {
        flavor = lib.mkOption {
          description = ''
            The base desktop environment or compositor to use.
          '';
          type = lib.types.enum ["hyprland"];
          default = "hyprland";
          example = "hyprland";
        };
      };
      wallpaper = lib.mkOption {
        description = ''
          Location of the wallpaper to use throughout the system.
        '';
        type = lib.types.path;
        example = lib.literalExpression ''
          ./wallpaper.jpg
        '';
      };
      monitors = {
        main = {
          id = lib.mkOption {
            description = ''
              The id of the main monitor.
            '';
            type = lib.types.str;
            example = "eDP-1";
          };
          width = lib.mkOption {
            description = ''
              The width of the main monitor.
            '';
            type = lib.types.int;
            example = 1920;
          };
          height = lib.mkOption {
            description = ''
              The height of the main monitor.
            '';
            type = lib.types.int;
            example = 1200;
          };
          scale = lib.mkOption {
            description = ''
              The scale of the main monitor.
            '';
            type = lib.types.float;
            default = 1.0;
            example = 1.0;
          };
          refreshRate = lib.mkOption {
            description = ''
              The refresh rate of the main monitor.
            '';
            type = lib.types.int;
            default = 60;
            example = 60;
          };
        };
        # Optional secondary monitor.
        secondary = {
          id = lib.mkOption {
            description = ''
              The id of the secondary monitor.
            '';
            type = lib.types.nullOr lib.types.str;
            default = null;
            example = "HDMI-1";
          };
          width = lib.mkOption {
            description = ''
              The width of the secondary monitor.
            '';
            type = lib.types.nullOr lib.types.int;
            default = null;
            example = 1920;
          };
          height = lib.mkOption {
            description = ''
              The height of the secondary monitor.
            '';
            type = lib.types.nullOr lib.types.int;
            default = null;
            example = 1200;
          };
          scale = lib.mkOption {
            description = ''
              The scale of the secondary monitor.
            '';
            type = lib.types.float;
            default = 1.0;
            example = 1.0;
          };
          refreshRate = lib.mkOption {
            description = ''
              The refresh rate of the secondary monitor.
            '';
            type = lib.types.int;
            default = 60;
            example = 60;
          };
        };
      };
    };
  };

  config = lib.mkIf (config.gui.enable && config.gui.environment.flavor == "hyprland") {
    features.ags.enable = true;
    features.alacritty.enable = true;
    features.audio.enable = true;
    features.bluetooth.enable = true;
    features.chromium.enable = true;
    features.cursor.enable = true;
    features.firefox.enable = true;
    features.fonts.enable = true;
    features.greeter.enable = true;
    features.gtk.enable = true;
    features.hyprland.enable = true;
    features.hyprlock.enable = true;
    features.security.enable = true;
    features.valent.enable = true;
    features.vscode.enable = true;

    hm = lib.mkIf config.gui.enable {
      # GUI applications.
      home.packages = with pkgs; [
        evince # Document viewer.
        file-roller # Archive manager.
        geary # Email client.
        gnome-calculator
        gnome-disk-utility # Disk utility.
        gnome-font-viewer # Font viewer.
        gnome-characters # Character map.
        gnome-maps # Maps.
        gnome-text-editor
        nautilus # File manager.
        totem # Video player.
        loupe # Image viewer.

        apostrophe # Minimal markdown editor.
        collision # File hash verifier.
        curtail # Image compressor.
        d-spy # D-Bus exploration tool.
        decibels # Audio player.
        fractal # Matrix client.
        github-desktop # GitHub desktop client.
        gnome-obfuscate # Image obfuscator.
        impression # Bootable drive writer.
        metadata-cleaner # Metadata cleaner.
        muzika # YouTube Music player.
        obsidian # Note-taking app.
        pods # Podman desktop client.
        seabird # Kubernetes desktop client.
        showtime # Video player.
        wildcard # Regex testing tool.
        zed-editor # Code editor.
      ];
    };
  };
}
