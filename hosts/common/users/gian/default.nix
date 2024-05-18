{
  pkgs,
  config,
  lib,
  ...
}: let
  ifTheyExist = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
in {
  # TODO: Use this as soon as proper password management is implemented. See:
  # https://mynixos.com/nixpkgs/option/users.mutableUsers. 
  #
  # users.mutableUsers = false;
  users.mutableUsers = true;
  users.users.gian = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups =
      [
        "wheel"
        "video"
        "audio"
      ]
      ++ ifTheyExist [
        "networkmanager"
        "docker"
        "podman"
        "git"
      ];

    openssh.authorizedKeys.keys = lib.splitString "\n" (builtins.readFile ../../../../home/gian/ssh.pub);
    packages = [pkgs.home-manager];
  };

  # TODO: Move this somewhere more suitable. Note: This should be an optional
  # feature per user, but as it needs user scoped services (located in the
  # home-manager directories), these should only be enabled if it's activated
  # for the user.
  programs = {
    _1password = {
      enable = true;
      package = pkgs._1password;
    };
    _1password-gui = {
      enable = true;
      package = pkgs._1password-gui;
      polkitPolicyOwners = [ "gian" ];
    };
  };

  home-manager.users.gian = import ../../../../home/gian/${config.networking.hostName}.nix;
}