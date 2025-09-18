{
  inputs,
  lib,
  pkgs,
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
        id = "DP-3"; # Physical position: 1st (leftmost).
        width = 3840;
        height = 2160;
        scale = 1.0;
        refreshRate = 120;
        rotation = 0;
        position = "0x0"; # Leftmost position.
      };
      secondary = {
        id = "HDMI-A-1"; # Physical position: 2nd.
        width = 3840;
        height = 2160;
        scale = 1.0;
        refreshRate = 120;
        rotation = 0;
        position = "3840x0"; # To the right of main.
      };
      tertiary = {
        id = "DP-2"; # Physical position: 3rd.
        width = 3840;
        height = 2160;
        scale = 1.0;
        refreshRate = 120;
        rotation = 0;
        position = "7680x0"; # To the right of secondary.
      };
      quaternary = {
        id = "DP-1"; # Physical position: 4th (rightmost).
        width = 3840;
        height = 2160;
        scale = 1.0;
        refreshRate = 120;
        rotation = 0;
        position = "11520x0"; # Rightmost position.
      };
    };
  };

  # Enable individual features.
  features.android.enable = true;
  features.ollama.enable = true;
  features.virtualization.enable = true;

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

    # TODO: Remove this redirect.
    systemd.sockets."https-loop-proxy" = {
      wantedBy = ["sockets.target"];
      listenStreams = ["127.0.0.1:443" "[::1]:443"];
    };
    systemd.services."https-loop-proxy".serviceConfig.ExecStart = "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd 127.0.0.1:8443";

    # System wide packages.
    environment = {
      systemPackages = with pkgs; [
        # Some additional tools.
        glxinfo
        pciutils
        vulkan-tools
        rocmPackages.rocminfo
      ];
    };

    networking.networkmanager = {
      enable = true;
    };

    # Enable GPU stuff.
    boot.initrd.kernelModules = ["amdgpu"];
    hardware = {
      graphics = {
        enable = true;
        enable32Bit = true;

        extraPackages = with pkgs; [
          amdvlk
        ];
        extraPackages32 = with pkgs.driversi686Linux; [
          amdvlk
        ];
      };

      amdgpu = {
        amdvlk = {
          enable = false;
          support32Bit.enable = false;
        };
        opencl.enable = true;
      };
    };
    environment.variables = {
      HSA_OVERRIDE_GFX_VERSION = "10.3.0"; # `gfx1030` for RX 6900 XT.
      AMD_VULKAN_ICD = "RADV"; # Force RADV over AMDVLK.
    };
    systemd.tmpfiles.rules = [
      "L+    /opt/rocm/hip   -    -    -     -    ${pkgs.rocmPackages.clr}"
    ];

    services.openssh.enable = true;
    users.users.root = {
      openssh.authorizedKeys.keys = lib.splitString "\n" (builtins.readFile ../../files/ssh.pub);
    };

    system.stateVersion = "24.11";
  };

  hm.home.stateVersion = "24.11";
}
