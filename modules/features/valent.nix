{
  config,
  lib,
  pkgs,
  ...
}: {
  options.features.valent.enable = lib.mkOption {
    description = ''
      Whether to enable [valent](https://github.com/andyholmes/valent).
    '';
    type = lib.types.bool;
    default = false;
    example = true;
  };

  config.os = lib.mkIf config.features.valent.enable {
    networking.firewall.allowedTCPPortRanges = [
      {
        from = 1714;
        to = 1764;
      }
    ];

    networking.firewall.allowedUDPPortRanges = [
      {
        from = 1714;
        to = 1764;
      }
    ];
  };

  config.hm = lib.mkIf config.features.valent.enable {
    home.packages = with pkgs; [
      valent # KDE Connect client.
    ];
  };
}
