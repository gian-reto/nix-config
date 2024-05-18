{
  config,
  inputs,
  lib,
  outputs,
  pkgs,
  ...
}: {
  imports =
    [
      # TODO: Set up impermanence.
      # inputs.impermanence.nixosModules.home-manager.impermanence
      ../features/cli
    ]
    ++ (builtins.attrValues outputs.homeManagerModules);

  nix = {
    package = lib.mkDefault pkgs.nix;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
        "ca-derivations"
      ];
      warn-dirty = false;
    };
  };

  systemd.user.startServices = "sd-switch";

  programs = {
    git.enable = true;
    home-manager.enable = true;
  };

  home = {
    username = lib.mkDefault "gian";
    homeDirectory = lib.mkDefault "/home/${config.home.username}";
    stateVersion = lib.mkDefault "24.05";
    sessionPath = ["$HOME/.local/bin"];
    # Fedault flake path for `nh`.
    sessionVariables = {
      FLAKE = "$HOME/Code/gian-reto/nix-config";
    };

    # TODO: Set up impermanence.
    # persistence = {
    #   "/persist/home/gian" = {
    #     defaultDirectoryMethod = "symlink";
    #     directories = [
    #       "Documents"
    #       "Downloads"
    #       "Pictures"
    #       "Videos"
    #       ".local/bin"
    #       ".local/share/nix" # Trusted settings and repl history.
    #     ];
    #     allowOther = true;
    #   };
    # };
  };
}