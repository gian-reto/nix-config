{
  config,
  lib,
  pkgs,
  ...
}: {
  options.features.tlp.enable = lib.mkOption {
    description = ''
      Whether to enable tlp (energy management).
    '';
    type = lib.types.bool;
    default = false;
    example = true;
  };

  config.os = lib.mkIf config.features.tlp.enable {
    services.power-profiles-daemon.enable = false;
    powerManagement.powertop.enable = true;
    services.tlp = {
      enable = true;

      # See: https://github.com/LunNova/nixos-configs/blob/dev/hosts/amayadori/default.nix.
      settings = {
        PCIE_ASPM_ON_AC = "performance";
        PCIE_ASPM_ON_BAT = "powersupersave";
        RUNTIME_PM_ON_AC = "auto";
        # Operation mode when no power supply can be detected: AC, BAT.
        TLP_DEFAULT_MODE = "BAT";
        # Operation mode select: 0=depend on power source, 1=always use TLP_DEFAULT_MODE.
        TLP_PERSISTENT_DEFAULT = "1";
        # I currently don't want this to be enabled, but it might be useful in
        # the future. 
        #
        # DEVICES_TO_DISABLE_ON_LAN_CONNECT = "wifi wwan";
        # DEVICES_TO_DISABLE_ON_WIFI_CONNECT = "wwan";
        # DEVICES_TO_DISABLE_ON_WWAN_CONNECT = "wifi";
      };
    };
  };
}