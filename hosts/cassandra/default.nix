{
  pkgs,
  inputs,
  ...
}: {
  osModules = [
    inputs.nixos-x13s.nixosModules.default
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
        scale = 1;
        refreshRate = 60;
      };
    };
  };
  laptop.enable = true;

  # Machine-specific configuration.
  os = {
    nixpkgs.config = {
      allowUnfree = true;
      allowUnfreePredicate = _: true;
    };

    nixos-x13s = {
      enable = true;

      kernel = "jhovold";
      bluetoothMac = "00:00:00:00:5A:AD";
    };
    specialisation = {
      mainline.configuration.nixos-x13s.kernel = "jhovold";
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
    };

    # System wide packages.
    environment.systemPackages = with pkgs; [
      glxinfo
      pciutils
    ];

    system.stateVersion = "24.05";
  };

  hm.home.stateVersion = "24.05";
}