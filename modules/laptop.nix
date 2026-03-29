{
  config,
  lib,
  ...
}: {
  options.laptop.enable = lib.mkOption {
    description = ''
      Whether to enable features specific to laptops.
    '';
    type = lib.types.bool;
    default = false;
    example = true;
  };

  config = lib.mkIf config.laptop.enable {
    os = {
      # Sleep.
      services.logind.settings.Login = {
        # Suspend first then hibernate when closing the lid.
        HandleLidSwitch = "suspend-then-hibernate";

        # Hibernate on power button pressed.
        HandlePowerKey = "hibernate";
        HandlePowerKeyLongPress = "poweroff";
      };

      systemd.sleep.settings.Sleep = {
        HibernateDelaySec = "45min";
        # Write image to disk then power off completely.
        HibernateMode = "shutdown";
        HibernateOnACPower = "no";
        # Deep sleep is not supported on this device.
        MemorySleepMode = "s2idle";
        # Set higher than `HibernateDelaySec` so the intermediate battery
        # estimation wakeup never fires before the hibernate deadline. On
        # `s2idle` the battery discharge rate often reads as zero, causing
        # systemd to loop back into suspend instead of hibernating, see:
        # https://github.com/systemd/systemd/issues/28008.
        SuspendEstimationSec = "1h";
        SuspendState = "mem";
      };

      # Force smallest possible hibernate image, see:
      # https://wiki.archlinux.org/title/Power_management/Suspend_and_hibernate#About_swap_partition/file_size.
      systemd.tmpfiles.rules = ["w /sys/power/image_size - - - - 0"];
    };
  };
}
