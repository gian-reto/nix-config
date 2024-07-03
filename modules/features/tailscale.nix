{
  config,
  lib,
  pkgs,
  ...
}: {
  options.features.tailscale.enable = lib.mkOption {
    description = ''
      Whether to enable tailscale.
    '';
    type = lib.types.bool;
    default = false;
    example = true;
  };

  config.os = lib.mkIf config.features.tailscale.enable {
    networking.firewall = {
      trustedInterfaces = ["tailscale0"];
      # Required to connect to Tailscale exit nodes.
      checkReversePath = "loose";
    };

    services.tailscale = {
      enable = true;

      extraUpFlags = ["--accept-routes" "--operator=${config.hmUsername}"];
      interfaceName = "tailscale0";
      openFirewall = true;
      useRoutingFeatures = "both";
    };
  };

  config.hm = lib.mkIf (config.features.tailscale.enable && config.gui.enable) {
    home.packages = with pkgs; [
      trayscale
    ];
  };
}
