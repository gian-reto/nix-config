{
  config,
  hmConfig,
  lib,
  pkgs,
  ...
}: {
  options.features.flatpak.enable = lib.mkOption {
    description = ''
      Whether to enable flatpak support.
    '';
    type = lib.types.bool;
    default = false;
    example = true;
  };

  config.os = lib.mkIf config.features.flatpak.enable {
    services.flatpak.enable = true;
    systemd.services.flatpak-repo = {
      wantedBy = ["multi-user.target"];
      path = [pkgs.flatpak];
      script = ''
        flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
      '';
    };
  };

  config.hm = lib.mkIf config.features.flatpak.enable {
    xdg.systemDirs.data = [
      "/var/lib/flatpak/exports/share"
      "${hmConfig.home.homeDirectory}/.local/share/flatpak/exports/share"
    ];
  };
}
