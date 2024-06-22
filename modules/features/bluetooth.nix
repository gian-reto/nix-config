{
  config,
  lib,
  pkgs,
  ...
}: {
  options.features.bluetooth.enable = lib.mkOption {
    description = ''
      Whether to enable bluetooth stuff.
    '';
    type = lib.types.bool;
    default = false;
    example = true;
  };

  config.os = lib.mkIf config.features.bluetooth.enable {
    hardware.bluetooth = {
      enable = true;

      powerOnBoot = true;
      settings = {
        General = { 
          # Necessary for AirPods.
          ControllerMode = "dual";
          # For `gnome-bluetooth` percentage (useful for `ags`).
          Experimental = "true";
        };
      };
    };
  };

  config.hm = lib.mkIf config.features.bluetooth.enable {
    home.packages = with pkgs; [
      bluetuith
      bluez
    ];
  };
}