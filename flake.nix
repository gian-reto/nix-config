{
  description = "Your new nix config";

  nixConfig = {
    extra-trusted-substituters = [
      "https://nix-config.cachix.org"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-config.cachix.org-1:Vd6raEuldeIZpttVQfrUbLvXJHzzzkS0pezXCVVjDG4="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    # Nix ecosystem.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.05";
    systems.url = "github:nix-systems/default-linux";

    nix = {
      url = "github:nixos/nix/2.22-maintenance";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    hardware.url = "github:nixos/nixos-hardware";

    # `home-manager`.
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager-stable = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    # ThinkPad X13s hardware support.
    nixos-x13s.url = "git+https://codeberg.org/adamcstephens/nixos-x13s";

    # Hyprland ecosystem.
    hyprland.url = "git+https://github.com/hyprwm/Hyprland?submodules=1";

    hyprland-contrib = {
      url = "github:hyprwm/contrib";
      inputs.nixpkgs.follows = "hyprland/nixpkgs";
    };

    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };

    hyprlock = {
      url = "github:hyprwm/hyprlock";
      inputs.hyprlang.follows = "hyprland/hyprlang";
      inputs.nixpkgs.follows = "hyprland/nixpkgs";
      inputs.systems.follows = "hyprland/systems";
    };

    hyprpaper = {
      url = "github:hyprwm/hyprpaper";
      inputs.hyprlang.follows = "hyprland/hyprlang";
      inputs.nixpkgs.follows = "hyprland/nixpkgs";
      inputs.systems.follows = "hyprland/systems";
    };
    
    # Third party programs, packaged with nix
    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    systems,
    ...
  } @ inputs: let
    inherit (self) outputs;
    lib = nixpkgs.lib // home-manager.lib;
    forEachSystem = f: lib.genAttrs (import systems) (system: f pkgsFor.${system});
    pkgsFor = lib.genAttrs (import systems) (
      system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        }
    );
  in {
    inherit lib;
    nixosModules = import ./modules/nixos;
    homeManagerModules = import ./modules/home-manager;

    overlays = import ./overlays { inherit inputs outputs; };

    packages = forEachSystem (pkgs: import ./pkgs { inherit pkgs; });
    formatter = forEachSystem (pkgs: pkgs.alejandra);

    # NixOS configuration entrypoint.
    # Available through `nixos-rebuild --flake .#hostname`.
    nixosConfigurations = {
      # Desktops & Laptops.

      # TODO
      # andromeda = lib.nixosSystem {
      #   modules = [
      #     ./hosts/andromeda
      #   ];
      #   specialArgs = { inherit inputs outputs; };
      # };

      # TODO
      cassandra = lib.nixosSystem {
        modules = [
          ./hosts/cassandra
        ];
        specialArgs = { inherit inputs outputs; };
      };

      # TODO
      # ganymede = lib.nixosSystem {
      #   modules = [
      #     ./hosts/ganymede
      #   ];
      #   specialArgs = { inherit inputs outputs; };
      # };

      # TODO
      # gilgamesh = lib.nixosSystem {
      #   modules = [
      #     ./hosts/gilgamesh
      #   ];
      #   specialArgs = { inherit inputs outputs; };
      # };

      # Servers.

      # TODO
      # medusa = lib.nixosSystem {
      #   modules = [
      #     ./hosts/medusa
      #   ];
      #   specialArgs = { inherit inputs outputs; };
      # };

      # Test VMs.

      # TODO
      # sandbox = lib.nixosSystem {
      #   modules = [
      #     ./hosts/sandbox
      #   ];
      #   specialArgs = { inherit inputs outputs; };
      # };
    };

    # Standalone `home-manager` configuration entrypoint.
    # Available through `home-manager --flake .#username@hostname`.
    homeConfigurations = {
      # Desktops & Laptops.

      # TODO
      # "gian@andromeda" = lib.homeManagerConfiguration {
      #   extraSpecialArgs = { inherit inputs outputs; };
      #   modules = [
      #     ./home/gian/andromeda.nix
      #     ./home/gian/nixpkgs.nix
      #   ];
      #   pkgs = pkgsFor.x86_64-linux;
      # };

      "gian@cassandra" = lib.homeManagerConfiguration {
        extraSpecialArgs = { inherit inputs outputs; };
        modules = [
          ./home/gian/cassandra.nix
          ./home/gian/nixpkgs.nix
        ];
        pkgs = pkgsFor.aarch64-linux;
      };

      # TODO
      # "gian@ganymede" = lib.homeManagerConfiguration {
      #   extraSpecialArgs = { inherit inputs outputs; };
      #   modules = [
      #     ./home/gian/ganymede.nix
      #     ./home/gian/nixpkgs.nix
      #   ];
      #   pkgs = pkgsFor.x86_64-linux;
      # };

      # TODO
      # "gian@gilgamesh" = lib.homeManagerConfiguration {
      #   extraSpecialArgs = { inherit inputs outputs; };
      #   modules = [
      #     ./home/gian/gilgamesh.nix
      #     ./home/gian/nixpkgs.nix
      #   ];
      #   pkgs = pkgsFor.x86_64-linux;
      # };

      # Servers.

      # TODO
      # "gian@medusa" = lib.homeManagerConfiguration {
      #   extraSpecialArgs = { inherit inputs outputs; };
      #   modules = [
      #     ./home/gian/medusa.nix
      #     ./home/gian/nixpkgs.nix
      #   ];
      #   pkgs = pkgsFor.x86_64-linux;
      # };

      # Test VMs.

      # TODO
      # "gian@sandbox" = lib.homeManagerConfiguration {
      #   extraSpecialArgs = { inherit inputs outputs; };
      #   modules = [
      #     ./home/gian/sandbox.nix
      #     ./home/gian/nixpkgs.nix
      #   ];
      #   pkgs = pkgsFor.x86_64-linux;
      # };
    };
  };
}