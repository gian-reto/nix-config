{
  lib,
  pkgs,
  ...
}: let
  username = "gian";
in {
  config = {
    hmUsername = username;

    os = {
      # TODO: Make users immutable and/or improve password situation.
      users.mutableUsers = true;
      users.users."${username}" = {
        isNormalUser = true;
        shell = pkgs.zsh;
        # TODO: Make some groups optional based on config.
        extraGroups = [
          "audio"
          "git"
          "lp"
          "networkmanager"
          "podman"
          "video"
          "wheel"
        ];

        openssh.authorizedKeys.keys = lib.splitString "\n" (builtins.readFile ../../files/ssh.pub);
      };
    };
  };
}
