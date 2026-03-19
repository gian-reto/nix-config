{
  config,
  hmConfig,
  lib,
  pkgs,
  ...
}: let
  addScript = pkgs.writeShellScriptBin "flatpak-remote-add-flathub" ''
    # Check whether the flathub remote is already correctly configured.
    if ${pkgs.flatpak}/bin/flatpak remotes --columns=name,url | ${pkgs.gnugrep}/bin/grep -q "^flathub[[:space:]]*https://dl.flathub.org/repo/$"; then
      echo "Flathub remote already exists, skipping."
      exit 0
    fi

    echo "Flathub remote not found, waiting for dl.flathub.org to be reachable..."
    for i in $(${pkgs.coreutils}/bin/seq 1 24); do
      if ${pkgs.iputils}/bin/ping -c 1 dl.flathub.org; then
        ${pkgs.flatpak}/bin/flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
        exit 0
      fi
      ${pkgs.coreutils}/bin/sleep 5
    done

    echo "Timed out waiting for dl.flathub.org to be reachable."
    exit 1
  '';
in {
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
      after = ["network-online.target" "nss-lookup.target"];
      wants = ["network-online.target" "nss-lookup.target"];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${addScript}/bin/flatpak-remote-add-flathub";
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
