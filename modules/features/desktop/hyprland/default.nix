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
  mod = "SUPER";
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
      inputs.hyprland-hyprpaper.packages.${pkgs.stdenv.hostPlatform.system}.hyprpaper
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

    wayland.windowManager.hyprland = {
      enable = true;

      package = null;
      portalPackage = null;

      # Disable home-manager's systemd integration since UWSM handles this.
      systemd.enable = false;

      settings = let
        active = "0x66585E6A";
        inactive = "0x66434852";
        uwsmExe = lib.getExe osConfig.programs.uwsm.package;
        # Helper to wrap app launches with uwsm.
        uwsmApp = cmd: "${uwsmExe} app -- ${cmd}";
        # Binds ${mod} + [shift +] {1..10} to [move to] workspace {1..10}.
        workspaces = builtins.concatLists (builtins.genList (
            x: let
              ws = let
                c = (x + 1) / 10;
              in
                builtins.toString (x + 1 - (c * 10));
            in [
              "${mod}, ${ws}, workspace, ${toString (x + 1)}"
              "${mod} CTRL, ${ws}, movetoworkspace, ${toString (x + 1)}"
            ]
          )
          10);
      in {
        exec-once = [
          "hyprctl setcursor ${hmConfig.home.pointerCursor.name} ${toString hmConfig.home.pointerCursor.size}"
          "${uwsmExe} app -- hyprpaper"
          "${uwsmExe} app -- hypridle"
          "${uwsmExe} app -- hyprlock"
          "${uwsmExe} app -- clipse -listen"
        ];

        general = {
          gaps_in = 3;
          gaps_out = 6;
          border_size = 1;
          "col.active_border" = active;
          "col.inactive_border" = inactive;

          resize_on_border = true;
        };

        misc = {
          disable_hyprland_logo = true;
          disable_hyprland_guiutils_check = true;
          disable_splash_rendering = true;
        };

        monitor =
          [
            "${cfg.monitors.main.id},${toString cfg.monitors.main.width}x${toString cfg.monitors.main.height}@${toString cfg.monitors.main.refreshRate},${cfg.monitors.main.position},${toString cfg.monitors.main.scale},transform,${toString cfg.monitors.main.rotation}"
          ]
          ++ (lib.optionals (cfg.monitors.secondary.id != null) ["${cfg.monitors.secondary.id},${toString cfg.monitors.secondary.width}x${toString cfg.monitors.secondary.height}@${toString cfg.monitors.secondary.refreshRate},${cfg.monitors.secondary.position},${toString cfg.monitors.secondary.scale},transform,${toString cfg.monitors.secondary.rotation}"])
          ++ (lib.optionals (cfg.monitors.tertiary.id != null) ["${cfg.monitors.tertiary.id},${toString cfg.monitors.tertiary.width}x${toString cfg.monitors.tertiary.height}@${toString cfg.monitors.tertiary.refreshRate},${cfg.monitors.tertiary.position},${toString cfg.monitors.tertiary.scale},transform,${toString cfg.monitors.tertiary.rotation}"])
          ++ (lib.optionals (cfg.monitors.quaternary.id != null) ["${cfg.monitors.quaternary.id},${toString cfg.monitors.quaternary.width}x${toString cfg.monitors.quaternary.height}@${toString cfg.monitors.quaternary.refreshRate},${cfg.monitors.quaternary.position},${toString cfg.monitors.quaternary.scale},transform,${toString cfg.monitors.quaternary.rotation}"]);

        # Bind workspaces to monitors.
        workspace =
          [
            "1,monitor:${cfg.monitors.main.id},default:true"
          ]
          ++ (lib.optionals (cfg.monitors.secondary.id != null) ["2,monitor:${cfg.monitors.secondary.id},default:true"])
          ++ (lib.optionals (cfg.monitors.tertiary.id != null) ["3,monitor:${cfg.monitors.tertiary.id},default:true"])
          ++ (lib.optionals (cfg.monitors.quaternary.id != null) ["4,monitor:${cfg.monitors.quaternary.id},default:true"]);

        input = {
          kb_layout = "us";
          kb_options = "compose:ralt";

          sensitivity = 0.45;

          follow_mouse = 1;
          natural_scroll = true;

          touchpad = {
            natural_scroll = true;
            scroll_factor = 0.5;
            clickfinger_behavior = true;
          };
        };

        gesture = [
          "3, horizontal, workspace"
        ];

        windowrule = let
          clipse = "match:class ^(clipse)$";
          fileChooser = "match:class ^(xdg-desktop-portal-gtk)$, match:title ^(Open Folder|Open File|Open Files|File Operation Progress)$";
          nautilusPreviewer = "match:class ^(org.gnome.NautilusPreviewer)$";
          op = "match:class ^(1Password)$, match:float true";
          pavucontrol = "match:class ^(org.pulseaudio.pavucontrol)$";
        in [
          "${clipse}, center on, float on, size 600 720"
          "${fileChooser}, center on, float on"
          "${nautilusPreviewer}, center on, float on, min_size 600 720"
          "${op}, center on"
          "${pavucontrol}, no_blur on"
        ];

        layerrule = [
          "match:namespace gtk4-layer-shell, blur on"
          "match:namespace gtk4-layer-shell, ignore_alpha 0.75"
          "match:namespace gtk4-layer-shell, xray 0"
        ];

        decoration = {
          rounding = 10;
          blur = {
            enabled = true;
            size = 4;
            passes = 3;
            new_optimizations = true;
            ignore_opacity = true;
            popups = true;
          };
        };

        animations = {
          enabled = true;
          animation = [
            "border, 1, 2, default"
            "fade, 1, 3, default"
            "windows, 1, 3, default, popin 80%"
            "workspaces, 1, 2, default, slide"
          ];
        };

        bindm = [
          "${mod},mouse:272,movewindow"
          "${mod},mouse:273,resizewindow"
        ];

        bind = let
          _1password = lib.getExe' pkgs._1password-gui-beta "1password";
          grimblast = lib.getExe inputs.hyprland-contrib.packages.${pkgs.stdenv.hostPlatform.system}.grimblast;
          tesseract = lib.getExe pkgs.tesseract;
          pactl = lib.getExe' pkgs.pulseaudio "pactl";
          notify-send = lib.getExe' pkgs.libnotify "notify-send";
          defaultAppFor = type: "${lib.getExe pkgs.handlr-regex} launch ${type}";
        in
          [
            # General binds.
            "${mod} SHIFT,R,exec,hyprctl reload; systemctl --user restart adw-shell"
            # Default applications.
            "${mod},Return,exec,${defaultAppFor "x-scheme-handler/terminal"}"
            "${mod},e,exec,${defaultAppFor "text/plain"}"
            "${mod},b,exec,${defaultAppFor "x-scheme-handler/https"}"
            # Applications.
            "CTRL SHIFT,SPACE,exec,${uwsmApp "${_1password} --quick-access"}"
            "${mod} SHIFT,V,exec,${uwsmApp "alacritty --class clipse -e 'clipse'"}"
            # Shell commands.
            "${mod},space,exec,ags request toggle-launcher --instance 'adw-shell'"
            # Window management.
            "${mod},Tab,cyclenext"
            "${mod} SHIFT,Tab,cyclenext,prev"
            "${mod},w,killactive"
            "${mod},q,killactive"
            "${mod},f,togglefloating"
            "${mod},left,workspace,-1"
            "${mod},right,workspace,+1"
            "${mod} CTRL,left,movetoworkspace,-1"
            "${mod} CTRL,right,movetoworkspace,+1"
            # Brightness control (only works if the system has `lightd`).
            ",XF86MonBrightnessUp,exec,light -A 5"
            ",XF86MonBrightnessDown,exec,light -U 5"
            # Volume control.
            ",XF86AudioRaiseVolume,exec,${pactl} set-sink-volume @DEFAULT_SINK@ +5%"
            ",XF86AudioLowerVolume,exec,${pactl} set-sink-volume @DEFAULT_SINK@ -5%"
            ",XF86AudioMute,exec,${pactl} set-sink-mute @DEFAULT_SINK@ toggle"
            ",XF86AudioMicMute,exec,${pactl} set-source-mute @DEFAULT_SOURCE@ toggle"
            # Screen lock.
            "${mod},l,exec,${lib.getExe hmConfig.programs.hyprlock.package}"
            # Screenshotting.
            "${mod} SHIFT,3,exec,${grimblast} --notify --freeze copy output"
            "${mod} SHIFT,4,exec,${grimblast} --notify --freeze copy area"
            # OCR.
            "${mod} SHIFT,5,exec,${grimblast} --freeze save area - | ${tesseract} - - | wl-copy && ${notify-send} -t 3000 'OCR result copied to buffer'"
          ]
          ++ workspaces
          ++ (
            let
              playerctl = lib.getExe' hmConfig.services.playerctld.package "playerctl";
              # playerctld = lib.getExe' hmConfig.services.playerctld.package "playerctld";
            in
              lib.optionals hmConfig.services.playerctld.enable [
                # Media control.
                ",XF86AudioMedia,exec,${playerctl} play-pause"
                ",XF86AudioPlay,exec,${playerctl} play-pause"
                ",XF86AudioNext,exec,${playerctl} next"
                ",XF86AudioPrev,exec,${playerctl} previous"
                ",XF86AudioStop,exec,${playerctl} stop"
              ]
          );
      };
    };
  };
}
