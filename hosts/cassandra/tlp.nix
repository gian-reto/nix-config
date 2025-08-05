# TLP settings for `cassandra` (Lenovo ThinkPad X13s).
# See: https://github.com/LunNova/nixos-configs/blob/dev/hosts/amayadori/default.nix.
{
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
}
