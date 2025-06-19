{
  config,
  lib,
  ...
}: {
  options.features.dev-local.enable = lib.mkOption {
    description = ''
      Whether to enable the `dev.local` reverse proxy.
      This uses `caddy` to run a reverse proxy for local development,
      which redirects to `localhost` and enables TLS.
    '';
    type = lib.types.bool;
    default = false;
    example = true;
  };

  config.os = lib.mkIf config.features.dev-local.enable {
    services.caddy = {
      enable = true;

      virtualHosts = let
        extraConfig = port: ''
          reverse_proxy localhost:${toString port}
          tls internal
        '';
      in {
        "3000.dev.local" = {
          extraConfig = extraConfig 3000;
        };
        "3001.dev.local" = {
          extraConfig = extraConfig 3001;
        };
        "3002.dev.local" = {
          extraConfig = extraConfig 3002;
        };
        "3003.dev.local" = {
          extraConfig = extraConfig 3003;
        };
        "3004.dev.local" = {
          extraConfig = extraConfig 3004;
        };
        "3005.dev.local" = {
          extraConfig = extraConfig 3005;
        };
      };
    };

    networking.hosts = {
      "127.0.0.1" = [
        "3000.dev.local"
        "3001.dev.local"
        "3002.dev.local"
        "3003.dev.local"
        "3004.dev.local"
        "3005.dev.local"
      ];
    };
  };
}
