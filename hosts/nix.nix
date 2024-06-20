{
  inputs,
  lib,
  osConfig,
  pkgs,
  ...
}: let
  nixSettings = {
    # Free up to 20GiB whenever there is less than 5GB left. Note: This setting
    # is in bytes, so we multiply with 1024 thrice.
    min-free = "${toString (5 * 1024 * 1024 * 1024)}";
    max-free = "${toString (20 * 1024 * 1024 * 1024)}";

    # Automatically optimise symlinks.
    auto-optimise-store = true;

    builders-use-substitutes = true;

    keep-going = true;
    # Show more log lines for failed builds.
    log-lines = 30;

    max-jobs = "auto";
    sandbox = true;

    warn-dirty = false;

    # Maximum number of parallel TCP connections used to fetch imports and
    # binary caches, 0 means no limit.
    http-connections = 0;

    keep-derivations = true;
    keep-outputs = true;

    accept-flake-config = true;

    extra-experimental-features = ["flakes" "nix-command"];

    substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      "https://hyprland.cachix.org"
      "https://cache.garnix.io"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
    ];

    trusted-users = [
      "root"
      "@wheel"
    ];
  };
  flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
in {
  hm.nix.settings = nixSettings;

  os = {
    documentation = {
      enable = true;
      
      doc.enable = false;
      man.enable = true;
      dev.enable = false;
    };

    nixpkgs.overlays = [(import ../pkgs/overlays)];

    nix = {
      package = inputs.nixpkgs-stable.legacyPackages.${pkgs.system}.nix;
      # Add each flake input as a registry and nix_path.
      registry = lib.mapAttrs (_: flake: {inherit flake;}) flakeInputs;
      nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;

      gc = {
        automatic = false;
      };

      settings = nixSettings;
    };
  };
}