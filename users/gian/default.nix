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
            "dialout" # Serial port access.
            "git"
            "lp"
            "networkmanager"
            "render"
            "video"
            "wheel"
          ]
          ++ (lib.optionals config.features.virtualization.enable [
            "kvm"
          ])
          ++ (lib.optionals config.features.containers.enable [
            "podman"
          ])
          ++ (lib.optionals config.features.android.enable [
            "adbusers"
          ]);

        openssh.authorizedKeys.keys = lib.splitString "\n" (builtins.readFile ../../files/ssh.pub);
      };
    };
  };
}
