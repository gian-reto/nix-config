{
  config,
  lib,
  ...
}: {
  options.features.network.enable = lib.mkOption {
    description = ''
      Whether to enable network stuff.
    '';
    type = lib.types.bool;
    default = false;
    example = true;
  };

  config.os = lib.mkIf config.features.network.enable {
    networking.networkmanager.enable = true;

    # Enable NetworkManager GUI if the GUI module is enabled.
    programs.nm-applet = lib.mkIf config.gui.enable {
      enable = true;
    };
  };
}