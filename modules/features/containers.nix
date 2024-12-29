{
  config,
  lib,
  ...
}: {
  options.features.containers.enable = lib.mkOption {
    description = ''
      Whether to enable containers (podman).
    '';
    type = lib.types.bool;
    default = false;
    example = true;
  };

  config.os = lib.mkIf config.features.containers.enable {
    virtualisation.podman = {
      enable = true;

      dockerCompat = true;
      dockerSocket.enable = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };
}
