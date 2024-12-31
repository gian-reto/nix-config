{
  description = "My NixOS configuration";

  outputs = {nixpkgs, ...} @ inputs: let
    forAllSystems = nixpkgs.lib.genAttrs [
      "aarch64-linux"
      "x86_64-linux"
    ];
    combinedManager = import (builtins.fetchTarball {
      url = "https://github.com/flafydev/combined-manager/archive/e7ba6d6b57ee03352022660fcd572c973b6b26db.tar.gz";
      sha256 = "sha256:11raq3s4d7b0crihx8pilhfp74xp58syc36xrsx6hdscyiild1z7";
    });
  in {
    packages = forAllSystems (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in
        import ./pkgs {inherit pkgs;}
    );
    formatter = forAllSystems (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in
        pkgs.alejandra
    );

    # Nixos config.
    nixosConfigurations = {
      # Workstation.
      atlas = combinedManager.nixosSystem {
        inherit inputs;

        configuration = {
          system = "x86_64-linux";

          modules = [
            # Modules.
            ./modules
            # Host configurations.
            ./hosts/common.nix
            ./hosts/atlas
            # User configurations.
            ./users/gian
          ];
        };
      };

      # ThinkPad X13s.
      cassandra = combinedManager.nixosSystem {
        inherit inputs;

        configuration = {
          system = "aarch64-linux";

          modules = [
            # Modules.
            ./modules
            # Host configurations.
            ./hosts/common.nix
            ./hosts/cassandra
            # User configurations.
            ./users/gian
          ];
        };
      };
    };
  };

  inputs = {
    # Nix ecosystem.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.11";
    hardware.url = "github:nixos/nixos-hardware";
    systems.url = "github:nix-systems/default-linux";

    nix = {
      url = "github:nixos/nix/2.22-maintenance";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Home Manager ecosystem.
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ThinkPad X13s hardware support.
    nixos-x13s.url = "github:gian-reto/x13s-nixos";

    # Hyprland ecosystem.
    hyprland.url = "git+https://github.com/hyprwm/Hyprland?submodules=1";

    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };

    hyprland-contrib = {
      url = "github:hyprwm/contrib";
      inputs.nixpkgs.follows = "hyprland/nixpkgs";
    };

    hyprland-hyprlock = {
      url = "github:hyprwm/hyprlock";
      inputs.hyprlang.follows = "hyprland/hyprlang";
      inputs.nixpkgs.follows = "hyprland/nixpkgs";
      inputs.systems.follows = "hyprland/systems";
    };

    hyprland-hyprpaper = {
      url = "github:hyprwm/hyprpaper";
      inputs.hyprlang.follows = "hyprland/hyprlang";
      inputs.nixpkgs.follows = "hyprland/nixpkgs";
      inputs.systems.follows = "hyprland/systems";
    };

    # Ghostty.
    ghostty = {
      url = "github:ghostty-org/ghostty";
      inputs.nixpkgs-unstable.follows = "nixpkgs";
      inputs.nixpkgs-stable.follows = "nixpkgs-stable";
    };

    ghostty-hm-module.url = "github:clo4/ghostty-hm-module";

    # Other stuff.
    ags.url = "github:aylur/ags";

    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    firefox-gnome-theme = {
      url = "github:rafaelmardojai/firefox-gnome-theme";
      flake = false;
    };
  };
}
