{
  pkgs,
  inputs,
  lib,
  ...
}: {
  osModules = [
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
        id = "DP-1";
        width = 1920;
        height = 1080;
        scale = 0.833333;
        refreshRate = 60;
        # Rotate 270 degrees.
        rotation = 3;
      };
      secondary = {
        id = "HDMI-A-1";
        width = 5120;
        height = 1440;
        scale = 1.0;
        refreshRate = 59.98;
        rotation = 0;
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
      hostName = "atlas";
    };

    # System wide packages.
    environment.systemPackages = with pkgs; [
      # Some additional tools.
      glxinfo
      pciutils
      vulkan-tools
    ];

    networking.networkmanager = {
      enable = true;
    };

    # Enable GPU acceleration.
    hardware.graphics = {
      enable = true;
    };

    services.openssh.enable = true;
    users.users.root = {
      openssh.authorizedKeys.keys = lib.splitString "\n" (builtins.readFile ../../files/ssh.pub);
    };

    system.stateVersion = "24.11";
  };

  hm.home.stateVersion = "24.11";
}
