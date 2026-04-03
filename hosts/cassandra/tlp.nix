# TLP settings for `cassandra` (Lenovo ThinkPad X13s / Snapdragon SC8280XP).
# Keep this focused on generic settings that are useful on ARM/Qualcomm.
{
  # === OPERATION ===
  # Operation mode when no power supply can be detected: AC, BAT.
  TLP_DEFAULT_MODE = "BAT";
  # Operation mode select: 0=depend on power source, 1=always use TLP_DEFAULT_MODE.
  TLP_PERSISTENT_DEFAULT = "0";

  # === CPU ===
  # `schedutil` is the appropriate generic governor for this platform.
  CPU_SCALING_GOVERNOR_ON_AC = "schedutil";
  CPU_SCALING_GOVERNOR_ON_BAT = "schedutil";

  # === RUNTIME POWER MANAGEMENT ===
  # Power down PCIe devices on battery.
  RUNTIME_PM_ON_AC = "on";
  RUNTIME_PM_ON_BAT = "auto";

  # Use the default PCIe policy on AC and the most aggressive power saving on battery.
  PCIE_ASPM_ON_AC = "default";
  PCIE_ASPM_ON_BAT = "powersupersave";

  # === USB ===
  # Enable USB autosuspend to reduce power consumption during sleep.
  USB_AUTOSUSPEND = "1";

  # Exclude some devices from USB autosuspend.
  USB_EXCLUDE_AUDIO = "1";
  USB_EXCLUDE_BTUSB = "1";
  USB_EXCLUDE_PRINTER = "1";
  USB_EXCLUDE_WWAN = "1";

  # === NETWORKING ===
  # Disable WiFi power saving to prevent connection drops.
  WIFI_PWR_ON_AC = "off";
  WIFI_PWR_ON_BAT = "on";

  # Disable Wake-on-LAN where supported.
  WOL_DISABLE = "Y";
}
