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
  };

  config.hm = lib.mkIf config.features.network.enable {
    # Enable NetworkManager GUI if the GUI module is enabled. Installing it
    # using `home-manager` fixes https://github.com/NixOS/nixpkgs/issues/32730.
    services.network-manager-applet = lib.mkIf config.gui.enable {
      enable = true;
    };
  };
}
