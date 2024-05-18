{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    inputs.nixos-x13s.nixosModules.default

    ./hardware-configuration.nix

    ../common/features
    ../common/users/gian

    ../common/optional/desktop/hyprland
    ../common/optional/pipewire.nix
    ../common/optional/systemd-boot.nix
    ../common/optional/tlp.nix
  ];

  nixos-x13s = {
    enable = true;
    kernel = "jhovold";
    bluetoothMac = "00:00:00:00:5A:AD";
  };
  specialisation = {
    mainline.configuration.nixos-x13s.kernel = "jhovold";
  };
  nix.settings = {
    substituters = [
      "https://nixos-x13s.cachix.org"
    ];
    trusted-public-keys = [
      "nixos-x13s.cachix.org-1:SzroHbidolBD3Sf6UusXp12YZ+a5ynWv0RtYF0btFos="
    ];
  };

  networking = {
    hostName = "cassandra";
  };

  # Fingerprint.
  services.fprintd.enable = true;
  services.fprintd.tod.enable = true;
  services.fprintd.tod.driver = pkgs.libfprint-2-tod1-goodix;

  # Network manager modemmanager setup.
  networking.networkmanager.fccUnlockScripts = [
    {
      id = "105b:e0c3";
      path = "${pkgs.modemmanager}/share/ModemManager/fcc-unlock.available.d/105b";
    }
  ];

  # Enable GPU acceleration.
  hardware.opengl = {
    enable = true;
    driSupport = true;
    package = 
      ((pkgs.mesa.override {
        galliumDrivers = [ "swrast" "freedreno" "zink" ];
        vulkanDrivers = [ "swrast" "freedreno" ];
        enableGalliumNine = false;
        enableOSMesa = false;
        enableOpenCL = false;
      }).overrideAttrs (old: {
        mesonFlags = old.mesonFlags ++ [
          "-Dgallium-vdpau=false"
          "-Dgallium-va=false"
          "-Dandroid-libbacktrace=disabled"
        ];
      })).drivers;
  };

  programs = {
    light.enable = true;
    dconf.enable = true;
  };

  system.stateVersion = "24.11";
}