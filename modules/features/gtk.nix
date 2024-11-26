{
  config,
  lib,
  pkgs,
  hmConfig,
  ...
}: {
  options.features.gtk.enable = lib.mkOption {
    description = ''
      Whether to enable GTK base configs.
    '';
    type = lib.types.bool;
    default = false;
    example = true;
  };

  config.hm = lib.mkIf config.features.gtk.enable {
    home.packages = with pkgs; [
      # `"adw-gtk3"` theme is required here, because if it's provided to
      # `package` below, it will apply to GTK4 as well (which I don't want).
      adw-gtk3
    ];

    gtk = {
      enable = true;

      # See: https://github.com/lassekongo83/adw-gtk3.
      theme = {
        name = "adw-gtk3-dark";
        package = pkgs.adw-gtk3;
      };
      iconTheme = {
        name = "Adwaita";
        package = pkgs.adwaita-icon-theme;
      };
      gtk3 = {
        bookmarks = let
          home = hmConfig.home.homeDirectory;
        in [
          "file://${home}/Code"
          "file://${home}/.config Config"
          "file://${home}/Documents"
          "file://${home}/Downloads"
          "file://${home}/Pictures"
          "file://${home}/Videos"
        ];
        extraConfig.gtk-application-prefer-dark-theme = true;
      };
      gtk4.extraConfig = {
        gtk-application-prefer-dark-theme = true;
      };
    };

    # Prevent theme package from applying to GTK4.
    xdg.configFile."gtk-4.0/gtk.css".enable = lib.mkForce false;

    # GNOME theme settings for apps that somehow don't pick up the configured
    # themes above.
    dconf.settings = {
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
        gtk-theme = "adw-gtk3-dark";
      };
    };
  };

  config.os = lib.mkIf config.features.gtk.enable {
    services = {
      # Needed for GNOME services outside of GNOME Desktop.
      dbus.packages = with pkgs; [
        gcr
        gnome-settings-daemon
        # GNOME desktop search engine. Used by some GNOME apps.
        tinysparql
      ];

      gvfs.enable = true;
      devmon.enable = true;
      udisks2.enable = true;
      upower.enable = true;
      gnome = {
        glib-networking.enable = true;
        sushi.enable = true;
        localsearch.enable = true;
      };
    };
  };
}
