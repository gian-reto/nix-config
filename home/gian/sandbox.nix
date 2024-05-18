{
  pkgs, 
  ...
}: {
  imports = [
    ./common
    ./features/desktop/hyprland
  ];
}