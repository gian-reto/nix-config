{
  config,
  lib,
  hmConfig,
  ...
}: {
  options.features.ssh.enable = lib.mkOption {
    description = ''
      Whether to enable SSH.
    '';
    type = lib.types.bool;
    default = false;
    example = true;
  };

  # TODO: Decouple this from `1password` and `gpg` (or make some stuff
  # optional).
  config.hm = lib.mkIf config.features.ssh.enable {
    programs.ssh = let
      gpgAgentPath = "${hmConfig.home.homeDirectory}/.gnupg-sockets/S.gpg-agent.ssh";
      _1passwordAgentPath = "${hmConfig.home.homeDirectory}/.1password/agent.sock";
    in {
      enable = true;
      extraConfig = ''
        Host github.com
          HostName github.com
          IdentityAgent ${gpgAgentPath}
          User git

        Host *
          IdentityAgent ${_1passwordAgentPath}
      '';
    };
  };
}