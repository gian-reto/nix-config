{
  config,
  hmConfig,
  inputs,
  lib,
  osConfig,
  pkgs,
  ...
}: let
  cfg = config.features.desktop;
in {
  imports = [
    ./hyprpaper.nix
    ./hypridle.nix
    ./hyprlock.nix
  ];

  config.os = lib.mkIf (cfg.enable && cfg.compositor == "hyprland") {
    environment.sessionVariables = {
      # Electron apps should use Wayland.
      NIXOS_OZONE_WL = "1";
      GTK_USE_PORTAL = "true";
    };

    programs = {
      hyprland = {
        enable = true;
        package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.default;

        withUWSM = true;
      };
      xwayland.enable = true;
    };

    xdg.portal = {
      enable = true;

      wlr.enable = lib.mkForce false;
      xdgOpenUsePortal = true;

      config = {
        common.default = ["gtk"];
        hyprland = {
          default = [
            "gtk"
            "hyprland"
          ];
          "org.freedesktop.impl.portal.Secret" = ["gnome-keyring"];
          "org.freedesktop.impl.portal.FileChooser" = ["xdg-desktop-portal-gtk"];
        };
      };
      configPackages = [
        pkgs.xdg-desktop-portal-gtk
        osConfig.programs.hyprland.portalPackage
        pkgs.xdg-desktop-portal
      ];
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
        xdg-desktop-portal
      ];
    };
  };

  config.hm = lib.mkIf (cfg.enable && cfg.compositor == "hyprland") {
    home.packages = with pkgs; [
      clipse
      hyprpicker
      inputs.hyprland-contrib.packages.${pkgs.stdenv.hostPlatform.system}.grimblast
      libnotify
      wf-recorder
      wl-clipboard
      wlr-randr
      xdg-utils
    ];

    home.sessionVariables = {
      QT_QPA_PLATFORM = "wayland";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      SDL_VIDEODRIVER = "wayland";
      XDG_SESSION_TYPE = "wayland";
    };

    xdg.mimeApps.enable = true;

    wayland.windowManager.hyprland = let
      cfgMonitors =
        lib.filter ({monitor, ...}: monitor.id != null)
        (lib.imap1 (workspace: monitor: {inherit workspace monitor;}) [
          cfg.monitors.main
          cfg.monitors.secondary
          cfg.monitors.tertiary
          cfg.monitors.quaternary
        ]);
      mod = "SUPER";
      uwsmExe = lib.getExe osConfig.programs.uwsm.package;
      uwsmApp = cmd: "${uwsmExe} app -- ${cmd}";

      context = {
        inherit mod;

        commands = let
          _1password = lib.getExe' pkgs._1password-gui "1password";
          brightnessctl = lib.getExe pkgs.brightnessctl;
          defaultAppFor = type: "${lib.getExe pkgs.handlr-regex} launch ${type}";
          grimblast = lib.getExe inputs.hyprland-contrib.packages.${pkgs.stdenv.hostPlatform.system}.grimblast;
          notify-send = lib.getExe' pkgs.libnotify "notify-send";
          pactl = lib.getExe' pkgs.pulseaudio "pactl";
          playerctl = lib.getExe' hmConfig.services.playerctld.package "playerctl";
          tesseract = lib.getExe pkgs.tesseract;
        in
          {
            # General binds.
            "${mod} + SHIFT + R" = "hyprctl reload; systemctl --user restart adw-shell";
            "${mod} + l" = "loginctl lock-session";

            # Default application binds.
            "${mod} + Return" = defaultAppFor "x-scheme-handler/terminal";
            "${mod} + e" = defaultAppFor "text/plain";
            "${mod} + b" = defaultAppFor "x-scheme-handler/https";

            # Utility binds.
            "${mod} + SHIFT + V" = uwsmApp "alacritty --class clipse -e 'clipse'";
            "${mod} + SPACE" = "ags request toggle-launcher --instance 'adw-shell'";
            "CTRL + SHIFT + SPACE" = uwsmApp "${_1password} --quick-access";

            # Screenshot binds.
            "${mod} + SHIFT + 3" = "${grimblast} --notify --freeze copy output";
            "${mod} + SHIFT + 4" = "${grimblast} --notify --freeze copy area";
            "${mod} + SHIFT + 5" = "${grimblast} --freeze save area - | ${tesseract} - - | wl-copy && ${notify-send} -t 3000 'OCR result copied to buffer'";

            # Backlight control binds.
            "XF86MonBrightnessDown" = "${brightnessctl} -c backlight set 10%-";
            "XF86MonBrightnessUp" = "${brightnessctl} -c backlight set 10%+";

            # Audio control binds.
            "XF86AudioLowerVolume" = "${pactl} set-sink-volume @DEFAULT_SINK@ -5%";
            "XF86AudioMicMute" = "${pactl} set-source-mute @DEFAULT_SOURCE@ toggle";
            "XF86AudioMute" = "${pactl} set-sink-mute @DEFAULT_SINK@ toggle";
            "XF86AudioRaiseVolume" = "${pactl} set-sink-volume @DEFAULT_SINK@ +5%";
          }
          // lib.optionalAttrs hmConfig.services.playerctld.enable {
            XF86AudioMedia = "${playerctl} play-pause";
            XF86AudioNext = "${playerctl} next";
            XF86AudioPlay = "${playerctl} play-pause";
            XF86AudioPrev = "${playerctl} previous";
            XF86AudioStop = "${playerctl} stop";
          };

        monitors =
          map ({monitor, ...}: {
            mode = "${toString monitor.width}x${toString monitor.height}@${toString monitor.refreshRate}";
            output = monitor.id;
            position = monitor.position;
            scale = toString monitor.scale;
            transform = monitor.rotation;
          })
          cfgMonitors;

        startupCommands =
          [
            "hyprctl setcursor ${hmConfig.home.pointerCursor.name} ${toString hmConfig.home.pointerCursor.size}"
            (uwsmApp "hyprlock")
            (uwsmApp "clipse -listen")
          ]
          ++ (lib.optionals hmConfig.services.hypridle.enable [
            (uwsmApp "hypridle")
          ]);

        workspaceRules =
          map ({
            workspace,
            monitor,
          }: {
            workspace = toString workspace;
            monitor = monitor.id;
            default = true;
          })
          cfgMonitors;
      };
    in {
      enable = true;

      configType = "lua";
      package = null;
      portalPackage = null;
      # Disable home-manager's systemd integration since UWSM handles this.
      systemd.enable = false;

      extraConfig = let
        toLua = lib.generators.toLua {};
      in ''
        local hm_xdg_config_home = os.getenv("XDG_CONFIG_HOME") or ${toLua hmConfig.xdg.configHome}
        package.path = hm_xdg_config_home .. "/hypr/?.lua;" .. hm_xdg_config_home .. "/hypr/?/init.lua;" .. package.path

        require("config")(${toLua context})
      '';

      extraLuaFiles.config = {
        content = ./config.lua;
        autoLoad = false;
      };
    };
  };
}
