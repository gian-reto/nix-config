{
  config,
  lib,
  pkgs,
  hmConfig,
  ...
}: let
  _1passwordAgentPath = "${hmConfig.home.homeDirectory}/.1password/agent.sock";
in {
  options.features.distributed-builds = {
    enable = lib.mkOption {
      description = ''
        Whether to enable distributed builds for `nix`.
      '';
      type = lib.types.bool;
      default = false;
      example = true;
    };

    enableNixIntegration = lib.mkOption {
      description = ''
        Whether to use distributed builds as the default build machine and substituter for `nix`.
      '';
      type = lib.types.bool;
      default = true;
      example = true;
    };
  };

  config.os = lib.mkIf config.features.distributed-builds.enable {
    # Configure SSH in every case.
    programs = {
      ssh = {
        extraConfig = ''
          Host eu.nixbuild.net
            PubkeyAcceptedKeyTypes ssh-ed25519
            ServerAliveInterval 60
            IPQoS throughput
            IdentityAgent ${_1passwordAgentPath}
        '';

        knownHosts = {
          nixbuild = {
            hostNames = ["eu.nixbuild.net"];
            publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPIQCZc54poJ8vqawd8TraNryQeJnvH1eLpIDgbiqymM";
          };
        };
      };
    };

    # Only enable Nix integration if specified. If disabled, users can use remote builders on-demand.
    nix = lib.mkIf config.features.distributed-builds.enableNixIntegration {
      # Build remotely on `nixbuild.net`.
      distributedBuilds = true;
      buildMachines = [
        {
          hostName = "eu.nixbuild.net";
          system = pkgs.stdenv.hostPlatform.system;
          maxJobs = 100;
          supportedFeatures = ["benchmark" "big-parallel"];
        }
      ];

      settings = {
        # Use nixbuild.net as a substituter (binary cache).
        substituters = [
          "ssh://eu.nixbuild.net"
        ];
        trusted-public-keys = [
          "nixbuild.net/DOBGQF-1:0xJhg75e5ASA7BYHJhE2UH1HD12W6nvo+Yd4C38mlnw="
        ];
      };
    };
  };
}
