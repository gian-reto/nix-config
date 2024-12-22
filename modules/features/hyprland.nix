{
  pkgs,
  lib,
  inputs,
  config,
  hmConfig,
  ...
}: let
  mod = "SUPER";
in {
  options.features.hyprland.enable = lib.mkOption {
    description = ''
      Whether to enable the Hyprland compositor.
    '';
    type = lib.types.bool;
    default = false;
    example = true;
  };

  config.os = lib.mkIf config.features.hyprland.enable {
    environment.sessionVariables = {
      # Electron apps should use Wayland.
      NIXOS_OZONE_WL = "1";
      GTK_USE_PORTAL = "true";
    };

    programs = {
      hyprland = {
        enable = true;

        package = pkgs.hyprland;
      };
      xwayland.enable = true;
    };

    xdg.portal = {
      enable = true;

      wlr.enable = lib.mkForce false;
      config = {
        common = {
          default = [
            "xdph"
            "gtk"
          ];
          "org.freedesktop.impl.portal.Secret" = ["gnome-keyring"];
          "org.freedesktop.portal.FileChooser" = ["xdg-desktop-portal-gtk"];
        };
      };
      extraPortals = with pkgs; [xdg-desktop-portal-gtk];
      xdgOpenUsePortal = true;
    };
  };

  config.hm = lib.mkIf config.features.hyprland.enable {
    home.packages = with pkgs; [
      clipse
      hyprpicker
      inputs.hyprland-contrib.packages.${pkgs.system}.grimblast
      inputs.hyprland-hyprpaper.packages.${pkgs.system}.hyprpaper
      libnotify
      wf-recorder
      wl-clipboard
      wlr-randr
      xdg-utils
    ];

    home.sessionVariables = {
      QT_QPA_PLATFORM = "wayland";
      SDL_VIDEODRIVER = "wayland";
      XDG_SESSION_TYPE = "wayland";
    };

    xdg = {
      mimeApps.enable = true;

      configFile."hypr/hyprpaper.conf".text = ''
        preload=${config.gui.wallpaper}

        wallpaper = ${config.gui.monitors.main.id},${config.gui.wallpaper}
        ${
          if (config.gui.monitors.secondary.id != null)
          then "wallpaper = ${config.gui.monitors.secondary.id},${config.gui.wallpaper}"
          else ""
        }
      '';
    };

    wayland.windowManager.hyprland = {
      enable = true;

      package = pkgs.hyprland;

      settings = let
        active = "0x66585E6A";
        inactive = "0x66434852";
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
        env = [
          "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"
        ];

        exec-once =
          [
            "dbus-update-activation-environment --systemd --all"
            "hyprpaper"
          ]
          ++ (
            lib.optionals config.features.hyprlock.enable [
              "hyprlock"
            ]
          )
          ++ (
            lib.optionals config.features.cursor.enable [
              "hyprctl setcursor ${hmConfig.home.pointerCursor.name} ${toString hmConfig.home.pointerCursor.size}"
            ]
          )
          ++ [
            "systemctl --user restart xdg-desktop-portal xdg-desktop-portal-hyprland"
          ]
          ++ (lib.optionals config.features.ags.enable ["ags -b hypr"])
          ++ [
            "sleep 5 && clipse -listen"
          ]
          ++ (lib.optionals config.features.bluetooth.enable [
            "sleep 5 && ${lib.getExe' pkgs.blueman "blueman-applet"}"
          ])
          ++ (lib.optionals config.features.security.enable [
            "sleep 5 && ${lib.getExe' pkgs._1password-gui-beta "1password"} --silent --ozone-platform-hint=x11"
          ]);

        monitor =
          [
            "${config.gui.monitors.main.id},${toString config.gui.monitors.main.width}x${toString config.gui.monitors.main.height}@${toString config.gui.monitors.main.refreshRate},${toString config.gui.monitors.main.offsetX}x${toString config.gui.monitors.main.offsetY},${toString config.gui.monitors.main.scale},transform,${toString config.gui.monitors.main.rotation}"
          ]
          ++ (lib.optionals (config.gui.monitors.secondary.id != null) ["${config.gui.monitors.secondary.id},${toString config.gui.monitors.secondary.width}x${toString config.gui.monitors.secondary.height}@${toString config.gui.monitors.secondary.refreshRate},${toString config.gui.monitors.secondary.offsetX}x${toString config.gui.monitors.secondary.offsetY},${toString config.gui.monitors.secondary.scale},transform,${toString config.gui.monitors.secondary.rotation}"]);

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
          disable_hyprland_qtutils_check = true;
          disable_splash_rendering = true;
        };

        input = {
          kb_layout = "us";

          sensitivity = 0.45;

          follow_mouse = 1;
          natural_scroll = true;

          touchpad = {
            natural_scroll = true;
            scroll_factor = 0.5;
            clickfinger_behavior = true;
          };
        };

        gestures = {
          workspace_swipe = true;
        };

        windowrulev2 = let
          clipse = "class:^(clipse)$";
          fileChooser = "class:^(xdg-desktop-portal-gtk)$,title:^(Open Folder|Open File|Open Files|File Operation Progress)$";
          nautilusPreviewer = "class:^(org.gnome.NautilusPreviewer)$";
          pavucontrol = "class:^(org.pulseaudio.pavucontrol)$";
        in [
          "float,${clipse}"
          "size 600 720,${clipse}"
          "center,${clipse}"
          "float,${fileChooser}"
          "center,${fileChooser}"
          "float,${nautilusPreviewer}"
          "maxsize 600 720,${nautilusPreviewer}"
          "center,${nautilusPreviewer}"
          "noblur,${pavucontrol}"
        ];

        layerrule = [
          "blur,bar-.*"
          "ignorezero,bar-.*"
          "blur,launcher"
          "ignorealpha 0.75,launcher"
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
          grimblast = lib.getExe inputs.hyprland-contrib.packages.${pkgs.system}.grimblast;
          tesseract = lib.getExe pkgs.tesseract;
          pactl = lib.getExe' pkgs.pulseaudio "pactl";
          notify-send = lib.getExe' pkgs.libnotify "notify-send";
          defaultAppFor = type: "${lib.getExe pkgs.handlr-regex} launch ${type}";
        in
          [
            # General binds.
            "${mod} SHIFT,R,exec,hyprctl reload; ags -b hypr -q; ags -b hypr" # Reload Hyprland and `ags`.
            # Default applications.
            "${mod},Return,exec,${defaultAppFor "x-scheme-handler/terminal"}"
            "${mod},e,exec,${defaultAppFor "text/plain"}"
            "${mod},b,exec,${defaultAppFor "x-scheme-handler/https"}"
            # Applications.
            "CTRL SHIFT,SPACE,exec,${_1password} --quick-access"
            "${mod} SHIFT,V,exec,alacritty --class clipse -e 'clipse'"
            "${mod},space,exec,ags -b hypr -t launcher"
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
            # Screenshotting.
            "${mod} SHIFT,3,exec,${grimblast} --notify --freeze copy output"
            "${mod} SHIFT,4,exec,${grimblast} --notify --freeze copy area"
            # To OCR.
            "${mod} SHIFT,5,exec,${grimblast} --freeze save area - | ${tesseract} - - | wl-copy && ${notify-send} -t 3000 'OCR result copied to buffer'"
          ]
          ++ workspaces
          ++ (
            let
              playerctl = lib.getExe' hmConfig.services.playerctld.package "playerctl";
              playerctld = lib.getExe' hmConfig.services.playerctld.package "playerctld";
            in
              lib.optionals hmConfig.services.playerctld.enable [
                # Media control.
                ",XF86AudioMedia,exec,${playerctl} play-pause"
                ",XF86AudioPlay,exec,${playerctl} play-pause"
                ",XF86AudioNext,exec,${playerctl} next"
                ",XF86AudioPrev,exec,${playerctl} previous"
                ",XF86AudioStop,exec,${playerctl} stop"
              ]
          )
          # Screen lock.
          ++ (lib.optionals config.features.hyprlock.enable [
            "${mod},l,exec, ${lib.getExe hmConfig.programs.hyprlock.package}"
          ]);
      };
    };
  };
}
