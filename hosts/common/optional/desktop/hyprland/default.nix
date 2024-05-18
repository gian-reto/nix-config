{ 
  pkgs, 
  ... 
}: {
  imports = [
    ./gnome-keyring.nix
    ./gnome-services.nix
    ./greetd.nix
    ./security.nix
  ];

  environment.variables = {
    # Electron apps should use wayland.
    NIXOS_OZONE_WL = "1";
  };

  environment.systemPackages = with pkgs; [
    evince # Document viewer.
    gnome-text-editor
    gnome.file-roller # Archive manager.
    gnome.gnome-calculator
    gnome.gnome-characters # Character map.
    gnome.nautilus # File manager.
    gnome.totem # Video player.
    loupe # Image viewer.
    muzika # Music player.
  ];
}