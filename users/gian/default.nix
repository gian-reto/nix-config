{
  config,
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
        # TODO: Make additional groups optional based on config.
        extraGroups =
          [
            "audio"
            "git"
            "kvm"
            "lp"
            "networkmanager"
            "podman"
            "video"
            "wheel"
          ]
          ++ (lib.optionals config.features.android.enable [
            "adbusers"
          ]);

        openssh.authorizedKeys.keys = lib.splitString "\n" (builtins.readFile ../../files/ssh.pub);
      };
    };
  };
}
