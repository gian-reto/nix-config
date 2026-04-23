{
  config,
  inputs,
  lib,
  osConfig,
  ...
}: let
  cfg = config.features.wireguard;

  hostName = osConfig.networking.hostName;
  serversTrustedPrefix = inputs.nix-secrets.networking.subnets.prefix.serversTrusted;

  mkSemicolonList = values:
    if values == []
    then ""
    else "${lib.concatStringsSep ";" values};";

  mkProfile = _: connection: {
    connection = {
      autoconnect = false;
      id = connection.displayName;
      interface-name = "wg0";
      type = "wireguard";
      uuid = connection.uuid;
    };

    wireguard = {
      mtu = 1412;
      private-key-flags = "1";
    };

    "wireguard-peer.$WIREGUARD_HOME_PUBLIC_KEY" = {
      allowed-ips = mkSemicolonList connection.allowedIPs;
      endpoint = "$WIREGUARD_HOME_ENDPOINT";
      persistent-keepalive = 25;
    };

    ipv4 = {
      address1 = cfg.clientAddress;
      dns = "${serversTrustedPrefix}1;";
      method = "manual";
    };

    ipv6.method = "disabled";
  };
in {
  options.features.wireguard = {
    enable = lib.mkOption {
      description = ''
        Whether to enable the standard WireGuard home VPN profiles in NetworkManager.
      '';
      type = lib.types.bool;
      default = false;
      example = true;
    };

    clientAddress = lib.mkOption {
      description = ''
        IPv4 address assigned to this host inside the WireGuard tunnel, including CIDR suffix.
      '';
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "10.0.100.3/32";
    };
  };

  config.os = let
    envFileName = "wireguard-home-networkmanager-env";
    secretKeys = {
      endpoint = "wireguard/home/endpoint";
      privateKey = "wireguard/${hostName}/private_key";
      publicKey = "wireguard/home/public_key";
    };
  in
    lib.mkIf cfg.enable {
      assertions = [
        {
          assertion = config.features.sops.enable;
          message = "features.wireguard.enable requires features.sops.enable.";
        }
        {
          assertion = hostName != null;
          message = "features.wireguard.enable requires networking.hostName to be set.";
        }
        {
          assertion = osConfig.networking.networkmanager.enable;
          message = "features.wireguard.enable requires networking.networkmanager.enable.";
        }
        {
          assertion = cfg.clientAddress != null;
          message = "features.wireguard.clientAddress must be set when enabling the WireGuard home feature.";
        }
      ];

      sops = let
        group = "networkmanager";
        mode = "0400";
        owner = "root";
      in {
        secrets = {
          "${secretKeys.endpoint}" = {
            inherit group mode owner;
          };
          "${secretKeys.privateKey}" = {
            inherit group owner;
            mode = "0440";
            restartUnits = ["nm-file-secret-agent.service"];
          };
          "${secretKeys.publicKey}" = {
            inherit group mode owner;
          };
        };

        templates."${envFileName}" = {
          inherit group mode owner;
          content = ''
            WIREGUARD_HOME_ENDPOINT="${osConfig.sops.placeholder."${secretKeys.endpoint}"}"
            WIREGUARD_HOME_PUBLIC_KEY="${osConfig.sops.placeholder."${secretKeys.publicKey}"}"
          '';
        };
      };

      networking.networkmanager.ensureProfiles = let
        connections = {
          wireguard-home-internet = {
            allowedIPs = ["0.0.0.0/0"];
            displayName = "Home + Internet";
            uuid = "24cb0d56-b4e9-4c9f-934d-a39317df632e";
          };

          wireguard-home-split = {
            allowedIPs = [
              # DNS server.
              "${serversTrustedPrefix}1/32"
              # Home server.
              "${serversTrustedPrefix}20/32"
            ];
            displayName = "Home (Split)";
            uuid = "f9e8326d-05ab-4e1f-b2c0-807f10756959";
          };
        };
      in {
        environmentFiles = [osConfig.sops.templates."${envFileName}".path];
        profiles = lib.mapAttrs mkProfile connections;
        secrets.entries =
          lib.mapAttrsToList (_: connection: {
            file = osConfig.sops.secrets."${secretKeys.privateKey}".path;
            key = "private-key";
            matchSetting = "wireguard";
            matchType = "wireguard";
            matchUuid = connection.uuid;
          })
          connections;
      };

      # Must run as the user to be able to function as a NetworkManager secret agent.
      systemd.services."nm-file-secret-agent".serviceConfig.User = config.hmUsername;
    };
}
