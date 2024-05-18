{
  lib,
  config,
  pkgs,
  ...
}: let 
  pointer = config.home.pointerCursor;
in {
  imports = [
    ../common

    ./hyprlock.nix
    ./hyprpaper.nix
    ./theme.nix
  ];

  xdg.portal = let
    hyprland = config.wayland.windowManager.hyprland.package;
    xdph = pkgs.xdg-desktop-portal-hyprland.override { inherit hyprland; };
  in {
    extraPortals = [xdph];
    configPackages = [hyprland];
  };

  home.packages = with pkgs; [
    inputs.hyprland-contrib.grimblast
    hyprpicker
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    package = pkgs.hyprland.override { wrapRuntimeDeps = false; };
    xwayland.enable = true;
    systemd.enable = true;

    settings = let
      active = "0x66585E6A";
      inactive = "0x66434852";
      # Binds SUPER + [shift +] {1..10} to [move to] workspace {1..10}.
      workspaces = builtins.concatLists (builtins.genList (
          x: let
            ws = let
              c = (x + 1) / 10;
            in
              builtins.toString (x + 1 - (c * 10));
          in [
            "SUPER, ${ws}, workspace, ${toString (x + 1)}"
            "SUPER SHIFT, ${ws}, movetoworkspace, ${toString (x + 1)}"
          ]
        )
        10);
    in {
      env = [
        "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"
      ];

      exec-once = [
        # Set cursor for Hyprland itself.
        "hyprctl setcursor ${pointer.name} ${toString pointer.size}"
        "hyprlock"
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
        disable_splash_rendering = true;
      };

      input = {
        kb_layout = "us";
        kb_options = "lv3:alt_switch";

        follow_mouse = 1;
        natural_scroll = true;

        touchpad = {
          natural_scroll = true;
          scroll_factor = 0.75;
          clickfinger_behavior = true;
        };
      };

      windowrulev2 = let
        nautilusPreviewer = "class:^(org.gnome.NautilusPreviewer)$";
      in [
        "float,${nautilusPreviewer}"
        "maxsize 600 720,${nautilusPreviewer}"
        "center,${nautilusPreviewer}"
      ];

      layerrule = [
        "blur,notifications"
        "ignorezero,notifications"
        "blur,wofi"
        "ignorezero,wofi"
        "noanim,wallpaper"
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
        drop_shadow = true;
      };

      animations = {
        enabled = true;
        animation = [
          "border, 1, 2, default"
          "fade, 1, 4, default"
          "windows, 1, 3, default, popin 80%"
          "workspaces, 1, 2, default, slide"
        ];
      };

      binds = {
        pass_mouse_when_bound = false;
      };

      bindm = [
        "SUPER,mouse:272,movewindow"
        "SUPER,mouse:273,resizewindow"
      ];

      bind = let
        _1password = lib.getExe pkgs._1password-gui;
        grimblast = lib.getExe pkgs.inputs.hyprland-contrib.grimblast;
        tesseract = lib.getExe pkgs.tesseract;
        pactl = lib.getExe' pkgs.pulseaudio "pactl";
        notify-send = lib.getExe' pkgs.libnotify "notify-send";
        defaultApp = type: "${lib.getExe pkgs.handlr-regex} launch ${type}";
      in
        [
          # Program bindings.
          "SUPER,Return,exec,${defaultApp "x-scheme-handler/terminal"}"
          "SUPER,e,exec,${defaultApp "text/plain"}"
          "SUPER,b,exec,${defaultApp "x-scheme-handler/https"}"
          # Applications.
          "CTRL SHIFT,SPACE,exec,${_1password} --quick-access"
          # Window management.
          "SUPER,Tab,cyclenext"
          "SUPER SHIFT,Tab,cyclenext,prev"
          "SUPER,w,killactive"
          "SUPER,q,killactive"
          "SUPER,f,togglefloating"
          "SUPER,left,workspace,-1"
          "SUPER,right,workspace,+1"
          "SUPER SHIFT,left,movetoworkspace,-1"
          "SUPER SHIFT,right,movetoworkspace,+1"
          # Brightness control (only works if the system has `lightd`).
          ",XF86MonBrightnessUp,exec,light -A 5"
          ",XF86MonBrightnessDown,exec,light -U 5"
          # Volume control.
          ",XF86AudioRaiseVolume,exec,${pactl} set-sink-volume @DEFAULT_SINK@ +5%"
          ",XF86AudioLowerVolume,exec,${pactl} set-sink-volume @DEFAULT_SINK@ -5%"
          ",XF86AudioMute,exec,${pactl} set-sink-mute @DEFAULT_SINK@ toggle"
          ",XF86AudioMicMute,exec,${pactl} set-source-mute @DEFAULT_SOURCE@ toggle"
          # Screenshotting.
          "SUPER SHIFT,3,exec,${grimblast} --notify --freeze copy output"
          "SUPER SHIFT,4,exec,${grimblast} --notify --freeze copy area"
          # To OCR.
          "SUPER SHIFT,5,exec,${grimblast} --freeze save area - | ${tesseract} - - | wl-copy && ${notify-send} -t 3000 'OCR result copied to buffer'"
        ]
        ++ workspaces
        ++ (
          let
            playerctl = lib.getExe' config.services.playerctld.package "playerctl";
            playerctld = lib.getExe' config.services.playerctld.package "playerctld";
          in
            lib.optionals config.services.playerctld.enable [
              # Media control.
              ",XF86AudioMedia,exec,${playerctl} play-pause"
              ",XF86AudioPlay,exec,${playerctl} play-pause"
              ",XF86AudioNext,exec,${playerctl} next"
              ",XF86AudioPrev,exec,${playerctl} previous"
              ",XF86AudioStop,exec,${playerctl} stop"
            ]
        )
        # TODO
        # ++
        # # Screen lock.
        # (
        #   let
        #     swaylock = lib.getExe config.programs.swaylock.package;
        #   in
        #     lib.optionals config.programs.swaylock.enable [
        #       "SUPER CTRL,q,exec,${swaylock} -S --grace 2"
        #     ]
        # )
        ++
        # Notification manager.
        (
          let
            makoctl = lib.getExe' config.services.mako.package "makoctl";
          in
            lib.optionals config.services.mako.enable [
              "SUPER,n,exec,${makoctl} dismiss"
              "SUPER SHIFT,n,exec,${makoctl} restore"
            ]
        )
        ++
        # Launcher.
        (
          let
            wofi = lib.getExe config.programs.wofi.package;
          in
            lib.optionals config.programs.wofi.enable [
              # Launch executables.
              "SUPER,x,exec,${wofi} -S run"
              # Launch applications.
              "SUPER,r,exec,${wofi} -S drun -x 10 -y 10 -W 25% -H 60%"
            ]
        );
    };
  };
}