{
  pkgs, 
  ...
}: {
  imports = [
    ./common
    ./features/desktop/hyprland
  ];

  # Monitor config.
  wayland.windowManager.hyprland.settings = {
    monitor = [
      "eDP-1,1920x1200@60,0x0,1"
    ];
  };
}