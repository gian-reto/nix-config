# Gathers the configs that I use on all hosts.
{
  pkgs,
  inputs,
  outputs,
  ...
}: {
  imports =
    [
      inputs.home-manager.nixosModules.home-manager
      ./locale.nix
      ./network.nix
      ./nix-ld.nix
      ./nix.nix
      ./podman.nix
      ./systemd-initrd.nix
      ./zsh.nix
    ]
    ++ (builtins.attrValues outputs.nixosModules);

  home-manager.useGlobalPkgs = true;
  home-manager.extraSpecialArgs = {
    inherit inputs outputs;
  };

  nixpkgs = {
    overlays = builtins.attrValues outputs.overlays;
    config = {
      allowUnfree = true;
    };
  };

  # System wide packages.
  environment.systemPackages = with pkgs; [
    glxinfo
    pciutils
  ];

  hardware.enableRedistributableFirmware = true;

  services = {
    dbus.implementation = "broker";
  };

  networking.domain = "hosts.internal.giantarnutzer.com";
}