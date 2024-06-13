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
    gtk = {
      enable = true;

      # See: https://github.com/lassekongo83/adw-gtk3.
      theme = {
        name = "adw-gtk3-dark";
        package = pkgs.adw-gtk3;
      };
      iconTheme = {
        name = "Adwaita";
        package = pkgs.gnome.adwaita-icon-theme;
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

    # TODO: Style QT like GTK (but move this to its own module).
    # qt = {
    #   enable = true;
    #   style.name = "adwaita-dark";
    # };

    # TODO: Enable if needed, else remove.
    # Also sets `org.freedesktop.appearance` `color-scheme`.
    # dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";
  };

  config.os = lib.mkIf config.features.gtk.enable {
    environment.systemPackages = [
      # Make GTK theme available for all users.
      hmConfig.gtk.theme.package
    ];

    services = {
      # Needed for GNOME services outside of GNOME Desktop.
      dbus.packages = with pkgs; [
        gcr
        gnome.gnome-settings-daemon
      ];

      gvfs.enable = true;
      devmon.enable = true;
      udisks2.enable = true;
      upower.enable = true;
      gnome = {
        glib-networking.enable = true;
        sushi.enable = true;
      };
    };
  };
}