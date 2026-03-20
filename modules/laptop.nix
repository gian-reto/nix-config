{
  config,
  lib,
  pkgs,
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
        # Suspend on lid close; a timer will trigger hibernation after 15 minutes.
        HandleLidSwitch = "suspend";

        # Hibernate on power button pressed.
        HandlePowerKey = "hibernate";
        HandlePowerKeyLongPress = "poweroff";
      };

      systemd.sleep.settings.Sleep = {
        # Write image to disk then power off completely.
        HibernateMode = "shutdown";
        # Deep sleep is not supported on this device.
        MemorySleepMode = "s2idle";
        SuspendState = "mem";
      };

      # Force smallest possible hibernate image, see:
      # https://wiki.archlinux.org/title/Power_management/Suspend_and_hibernate#About_swap_partition/file_size.
      systemd.tmpfiles.rules = ["w /sys/power/image_size - - - - 0"];

      # After 60 minutes of suspend, free memory and hibernate. Using a timer
      # with `WakeSystem=yes` ensures the system wakes from suspend after the
      # delay to perform hibernation. Anchored to `sleep.target`, which
      # activates before the suspend and deactivates on resume, so `PartOf`
      # correctly cancels the timer when the device is awoken before the delay.
      systemd.timers."hibernate-after-suspend" = {
        timerConfig = {
          OnActiveSec = "1h";
          WakeSystem = true;
        };
        wantedBy = ["sleep.target"];
        partOf = ["sleep.target"];
        after = ["sleep.target"];
      };
      systemd.services."hibernate-after-suspend" = {
        serviceConfig = {
          Type = "oneshot";
          ExecStart = pkgs.writeShellScript "hibernate-after-suspend" ''
            ${pkgs.coreutils}/bin/sync
            echo 3 > /proc/sys/vm/drop_caches
            echo 1 > /proc/sys/vm/compact_memory
            ${pkgs.coreutils}/bin/sleep 5
            systemctl hibernate
          '';
        };
      };
    };
  };
}
