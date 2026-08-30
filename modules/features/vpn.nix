{
  config,
  lib,
  ...
}: {
  options.features.vpn.enable = lib.mkOption {
    description = ''
      Whether to enable VPN tools.
    '';
    type = lib.types.bool;
    default = false;
    example = true;
  };

  config.os = lib.mkIf config.features.vpn.enable {
    services.mullvad-vpn = {
      enable = true;

      gui.enable = config.gui.enable;
    };
  };
}
