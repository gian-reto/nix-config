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
    systemd.services.flatpak-remote-add-flathub = {
      description = "Add Flathub repository for Flatpak";
      wantedBy = ["multi-user.target"];
      after = ["network-online.target"];
      wants = ["network-online.target"];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.flatpak}/bin/flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo";
        # Restart on failure (e.g., network not actually connected yet).
        Restart = "on-failure";
        RestartSec = "30s";
        # Give up after 20 attempts to avoid infinite retries.
        StartLimitBurst = 20;
      };
    };
  };

  config.hm = lib.mkIf config.features.flatpak.enable {
    xdg.systemDirs.data = [
      "/var/lib/flatpak/exports/share"
      "${hmConfig.home.homeDirectory}/.local/share/flatpak/exports/share"
    ];
  };
}
