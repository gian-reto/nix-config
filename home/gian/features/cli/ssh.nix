{
  config,
  lib,
  ...
}: let
  gpgAgentPath = "${config.home.homeDirectory}/.gnupg-sockets/S.gpg-agent.ssh";
  _1passwordAgentPath = "${config.home.homeDirectory}/.1password/agent.sock";
in {
  programs.ssh = {
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

  # TODO: Set up impermanence.
  # home.persistence = {
  #   "/persist/home/gian" = {
  #     directories = [
  #       ".ssh"
  #     ];
  #   };
  # };
}