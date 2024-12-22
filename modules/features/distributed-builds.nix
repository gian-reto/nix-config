{
  config,
  lib,
  pkgs,
  hmConfig,
  ...
}: let
  _1passwordAgentPath = "${hmConfig.home.homeDirectory}/.1password/agent.sock";
in {
  options.features.distributed-builds.enable = lib.mkOption {
    description = ''
      Whether to enable distributed builds for `nix`.
    '';
    type = lib.types.bool;
    default = false;
    example = true;
  };

  config.os = lib.mkIf config.features.distributed-builds.enable {
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

    nix = {
      # Build remotely on `nixbuild.net`.
      distributedBuilds = true;
      buildMachines = [
        {
          hostName = "eu.nixbuild.net";
          system = pkgs.system;
          maxJobs = 100;
          supportedFeatures = ["benchmark" "big-parallel"];
        }
      ];
    };
  };
}
