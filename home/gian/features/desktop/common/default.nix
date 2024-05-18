{
  pkgs, 
  ...
}: {
  imports = [
    ./1password.nix
    ./alacritty.nix
    ./cursor.nix
    ./firefox.nix
    ./font.nix
    ./gtk.nix
    ./mako.nix
    ./pavucontrol.nix
    ./playerctl.nix
    ./vscode.nix
    ./wofi.nix
  ];

  xdg.mimeApps.enable = true;
  home.packages = with pkgs; [
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

    MOZ_ENABLE_WAYLAND = 1;

    BROWSER = "x-www-browser";
  };

  # Also sets `org.freedesktop.appearance` `color-scheme`.
  dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";

  xdg.portal = {
    enable = true;
    extraPortals = [pkgs.xdg-desktop-portal-wlr];
  };
}