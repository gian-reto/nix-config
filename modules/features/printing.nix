{
  config,
  lib,
  pkgs,
  ...
}: {
  options.features.printing.enable = lib.mkOption {
    description = ''
      Whether to enable printing support through CUPS with Canon printer drivers.
    '';
    type = lib.types.bool;
    default = false;
    example = true;
  };

  config.os = lib.mkIf config.features.printing.enable {
    # Enable CUPS.
    services.printing = {
      enable = true;

      # Include Canon printer drivers and other common drivers.
      drivers = with pkgs; [
        # Canon printer drivers.
        canon-cups-ufr2 # Canon printer drivers.

        # Additional useful drivers.
        gutenprint-bin
      ];

      # Automatic printer discovery.
      browsed.enable = true;
    };

    # Avahi for network printer discovery.
    services.avahi = {
      enable = true;

      nssmdns4 = true;
    };

    # GUI printer management.
    programs.system-config-printer.enable = true;
  };
}
