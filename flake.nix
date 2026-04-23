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
        // (
          if system == "aarch64-linux"
          then {
            # Fairphone 5 boot image (for flashing to `boot` partition).
            orion-boot-image = inputs.nixos-fairphone-fp5.lib.mkBootImage inputs.self.nixosConfigurations.orion pkgs;
            # Fairphone 5 rootfs image (for flashing to `userdata` partition).
            orion-rootfs-image = inputs.nixos-fairphone-fp5.lib.mkRootfsImageWithHomeManager inputs.self.nixosConfigurations.orion pkgs;
          }
          else {}
        )
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

      # Fairphone 5.
      orion = combinedManager.nixosSystem {
        inherit inputs;

        configuration = {
          system = "aarch64-linux";

          modules = [
            # Modules.
            ./modules
            # Host configurations.
            ./hosts/common.nix
            ./hosts/orion
            # User configurations.
            ./users/gian
          ];
        };
      };

      # ThinkPad X13 Gen 4.
      tycho = combinedManager.nixosSystem {
        inherit inputs;

        configuration = {
          system = "x86_64-linux";

          modules = [
            # Modules.
            ./modules
            # Host configurations.
            ./hosts/common.nix
            ./hosts/tycho
            # User configurations.
            ./users/gian
          ];
        };
      };

      # Server configuration.
      trantor = combinedManager.nixosSystem {
        inherit inputs;

        configuration = {
          system = "x86_64-linux";

          modules = [
            # Modules.
            ./modules
            # Host configurations.
            ./hosts/common.nix
            ./hosts/trantor
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
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-helium.url = "github:nixos/nixpkgs/pull/498572/head";
    hardware.url = "github:nixos/nixos-hardware";
    systems.url = "github:nix-systems/default-linux";

    nix = {
      url = "github:nixos/nix/latest-release";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-services = {
      url = "git+ssh://git@github.com/gian-reto/nix-services?ref=main&rev=9a4ed7ac1d4516671b509c5ea06fda1b359bdc09";
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

    # Lenovo X13s hardware support.
    x13s-nixos = {
      url = "github:gian-reto/x13s-nixos/5abbd4cf4392dd79d8498da92c9ccde71597f4cb";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Fairphone 5 hardware support.
    nixos-fairphone-fp5 = {
      url = "git+https://github.com/gian-reto/nixos-fairphone-fp5?ref=251208-phosh&rev=912e96b550c096a45cb48d9204ca6cd640b00ea0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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

    hyprland-hyprshutdown = {
      url = "github:hyprwm/hyprshutdown";
      inputs.nixpkgs.follows = "hyprland/nixpkgs";
      inputs.systems.follows = "hyprland/systems";
    };

    # VSCode stuff.
    vscode-insiders = {
      url = "github:auguwu/vscode-insiders-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Other stuff.
    adw-shell = {
      url = "github:gian-reto/adw-shell/abaaa31d8a8e1d78b14c3d093d645614a14a70ee";
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

    helium = {
      url = "github:cjavad/nixpille-helium";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # LLM stuff.
    mcp-servers-nix = {
      url = "github:natsukium/mcp-servers-nix";
      # inputs.nixpkgs.follows = "nixpkgs";
    };
    mcp-nixos = {
      url = "github:utensils/mcp-nixos";
      # inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
