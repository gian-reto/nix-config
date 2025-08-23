# TLP settings for `tycho` (Lenovo ThinkPad X13 Gen 4, AMD Ryzen 7 PRO 7840U).
# Optimized for high performance on AC and aggressive power saving on battery.
{
  # === OPERATION ===
  # Operation mode when no power supply can be detected: AC, BAT.
  TLP_DEFAULT_MODE = "BAT";
  # Operation mode select: 0=depend on power source, 1=always use TLP_DEFAULT_MODE.
  TLP_PERSISTENT_DEFAULT = "0";

  # === CPU ===
  # AMD Zen 4 supports amd-pstate driver for optimal power management.
  CPU_DRIVER_OPMODE_ON_AC = "active";
  CPU_DRIVER_OPMODE_ON_BAT = "active";

  # Scaling governors.
  CPU_SCALING_GOVERNOR_ON_AC = "performance";
  CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

  # High performance on AC, maximum power saving on battery.
  CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
  CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power";

  # Enable turbo boost on AC for maximum performance, disable on battery.
  CPU_BOOST_ON_AC = "1";
  CPU_BOOST_ON_BAT = "0";

  # === Graphics ===
  # Graphics
  RADEON_DPM_PERF_LEVEL_ON_AC = "auto";
  RADEON_DPM_PERF_LEVEL_ON_BAT = "auto";
  RADEON_DPM_STATE_ON_AC = "performance";
  RADEON_DPM_STATE_ON_BAT = "battery";
  AMDGPU_ABM_LEVEL_ON_AC = "0";
  AMDGPU_ABM_LEVEL_ON_BAT = "2";

  # === PLATFORM ===
  # Use performance profile on AC, low-power on battery.
  PLATFORM_PROFILE_ON_AC = "performance";
  PLATFORM_PROFILE_ON_BAT = "low-power";

  # Newer ThinkPads don't support anything other than `s2idle` anymore...
  MEM_SLEEP_ON_AC = "s2idle";
  MEM_SLEEP_ON_BAT = "s2idle";

  # === RUNTIME POWER MANAGEMENT ===
  # Power down PCIe devices on battery.
  RUNTIME_PM_ON_AC = "on";
  RUNTIME_PM_ON_BAT = "auto";

  # Use default on AC, maximum power savings on battery.
  PCIE_ASPM_ON_AC = "default";
  PCIE_ASPM_ON_BAT = "powersupersave";

  # === USB ===
  # Enable USB autosuspend to reduce power consumption during sleep.
  USB_AUTOSUSPEND = "1";

  # Exlude Quectel EM05-G modem from autosuspend.
  # Maybe does not work, but it doesn't hurt.
  USB_DENYLIST = "2c7c:030a";

  # Exclude some devices from USB autosuspend.
  USB_EXCLUDE_AUDIO = "1";
  USB_EXCLUDE_BTUSB = "1";
  USB_EXCLUDE_PRINTER = "1";
  USB_EXCLUDE_WWAN = "1";

  # === NETWORKING ===
  # Disable WiFi power saving to prevent connection drops.
  WIFI_PWR_ON_AC = "off";
  WIFI_PWR_ON_BAT = "off";

  # Wake-on-LAN settings.
  WOL_DISABLE = "Y";
}
