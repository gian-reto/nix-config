{
  config,
  lib,
  hmConfig,
  ...
}: let
  # TODO: Decouple this from `1password` and `gpg` (or make some stuff optional).
  gpgAgentPath = "${hmConfig.home.homeDirectory}/.gnupg-sockets/S.gpg-agent.ssh";
  _1passwordAgentPath = "${hmConfig.home.homeDirectory}/.1password/agent.sock";
in {
  options.features.ssh.enable = lib.mkOption {
    description = ''
      Whether to enable SSH.
    '';
    type = lib.types.bool;
    default = false;
    example = true;
  };

  config.hm = lib.mkIf config.features.ssh.enable {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;

      settings = {
        "Host github.com" = {
          HostName = "github.com";
          IdentityAgent = gpgAgentPath;
          User = "git";
        };

        "Host atlas" = {
          HostName = "192.168.10.10";
          IdentityAgent = gpgAgentPath;
          User = "root";
        };

        "Host cassandra" = {
          HostName = "192.168.10.11";
          IdentityAgent = gpgAgentPath;
          User = "root";
        };

        "Host orion" = {
          HostName = "192.168.10.13";
          IdentityAgent = gpgAgentPath;
          User = "root";
        };

        "Host trantor" = {
          HostName = "192.168.20.20";
          IdentityAgent = gpgAgentPath;
          User = "root";
        };

        "Host tycho" = {
          HostName = "192.168.10.12";
          IdentityAgent = gpgAgentPath;
          User = "root";
        };

        "Host vm" = {
          HostName = "localhost";
          Port = 2222;
          IdentityAgent = gpgAgentPath;
          User = "root";
        };

        "*" = {
          AddKeysToAgent = "no";
          Compression = false;
          ControlMaster = "no";
          ControlPath = "~/.ssh/master-%r@%n:%p";
          ControlPersist = "no";
          ForwardAgent = false;
          HashKnownHosts = false;
          IdentityAgent = _1passwordAgentPath;
          ServerAliveCountMax = 3;
          ServerAliveInterval = 0;
          UserKnownHostsFile = "~/.ssh/known_hosts";
        };
      };
    };
  };
}
