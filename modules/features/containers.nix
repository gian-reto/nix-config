{
  config,
  lib,
  pkgs,
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
    virtualisation = {
      # Always use `docker.io` as the default registry for unqualified image names
      # to avoid ambiguity.
      containers.registries.search = [
        "docker.io"
      ];
      docker.enable = lib.mkForce false;
      podman = {
        enable = true;

        dockerCompat = true;
        dockerSocket.enable = true;
        defaultNetwork.settings.dns_enabled = true;
      };
    };

    environment.systemPackages = with pkgs; [
      podman-compose
    ];
  };
}
