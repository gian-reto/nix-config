{
  inputs,
  lib,
  pkgs,
  ...
}: {
  osModules = [
    inputs.hardware.nixosModules.lenovo-thinkpad-x13-amd
    inputs.disko.nixosModules.disko
    ./disk-configuration.nix
    ./hardware-configuration.nix
  ];

  # Enable my modules!
  gui = {
    enable = true;

    environment.flavor = "hyprland";
    wallpaper = ../../files/wallpaper.jpg;
    monitors = {
      main = {
        id = "eDP-1";
        width = 1920;
        height = 1200;
        scale = 1.0;
        refreshRate = 60;
      };
    };
  };

  # Machine-specific configuration.
  os = {
    programs = {
      light.enable = true;
    };

    nixpkgs.config = {
      allowUnfree = true;
      allowUnfreePredicate = _: true;
    };

    boot = {
      initrd.systemd.enable = true;
      loader = {
        systemd-boot = {
          enable = true;
          consoleMode = "max";
        };
        efi.canTouchEfiVariables = true;
      };
    };

    networking = {
      hostName = "tycho";
    };

    # System wide packages.
    environment = {
      systemPackages = with pkgs; [
        # Some additional tools.
        amdgpu_top
        glxinfo
        rocmPackages.rocminfo
        vulkan-tools
      ];

      # Force RADV over AMDVLK.
      variables.AMD_VULKAN_ICD = "RADV";
    };

    # GPU stuff.
    hardware = {
      graphics = {
        # Mesa is installed with this option.
        enable = true;
        enable32Bit = true;

        extraPackages = with pkgs; [
          # See: https://nixos.wiki/wiki/Accelerated_Video_Playback.
          libva
          # OpenCL support, see: https://wiki.nixos.org/wiki/AMD_GPU#OpenCL.
          rocmPackages.clr.icd
          clinfo
        ];
      };

      amdgpu.initrd.enable = true;
    };

    # Power management.
    services.power-profiles-daemon.enable = false;
    powerManagement.powertop.enable = true;
    services.tlp = {
      enable = true;

      settings = import ./tlp.nix;
    };

    # Fingerprint.
    services.fprintd.enable = true;

    # Network manager modemmanager setup.
    services.udev.packages = [pkgs.modemmanager];
    services.dbus.packages = [pkgs.modemmanager];
    systemd.packages = [pkgs.modemmanager];
    systemd.units.ModemManager.enable = true;
    networking.networkmanager = let
      fccUnlockScript = rec {
        id = "2c7c:030a";
        path = "${pkgs.modemmanager}/share/ModemManager/fcc-unlock.available.d/${id}";
      };
    in {
      enable = true;

      fccUnlockScripts = [fccUnlockScript];
    };
    systemd.services.ModemManager = {
      aliases = ["dbus-org.freedesktop.ModemManager1.service"];
      wantedBy = ["NetworkManager.service"];
      partOf = ["NetworkManager.service"];
      after = ["NetworkManager.service"];
    };

    services.openssh.enable = true;
    users.users.root = {
      openssh.authorizedKeys.keys = lib.splitString "\n" (builtins.readFile ../../files/ssh.pub);
    };

    system.stateVersion = "25.05";
  };

  hm.home.stateVersion = "25.05";
}
