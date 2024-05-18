{
  pkgs,
  ...
}: {
  gtk = {
    enable = true;
    # See: https://github.com/lassekongo83/adw-gtk3.
    theme = {
      package = pkgs.adw-gtk3;
      name = "adw-gtk3-dark";
    };
    gtk3.extraConfig = {
      Settings = ''
        gtk-application-prefer-dark-theme=1
      '';
    };
    gtk4.extraConfig = {
      Settings = ''
        gtk-application-prefer-dark-theme=1
      '';
    };
  };

  xdg.portal.extraPortals = [pkgs.xdg-desktop-portal-gtk];
}