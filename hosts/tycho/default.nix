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

    # System wide packages.
    environment = {
      systemPackages = with pkgs; [
        # Some additional tools.
        amdgpu_top
        glxinfo
        rocmPackages.rocminfo
        vulkan-tools

        # Modem support.
        modemmanager
        libmbim # MBIM protocol support for the Quectel EM05-G modem.
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

    # NetworkManager / ModemManager setup.
    networking = {
      hostName = "tycho";

      # Cellular modem configuration.
      modemmanager = {
        enable = true;
        package = pkgs.modemmanager;

        fccUnlockScripts = [
          {
            id = "2c7c:030a"; # Quectel EM05-G modem USB ID.
            path = "${pkgs.modemmanager}/share/ModemManager/fcc-unlock.available.d/2c7c:030a";
          }
        ];
      };

      networkmanager.ensureProfiles.profiles.swisscom = {
        connection = {
          id = "Swisscom";
          type = "gsm";
          autoconnect = true;
          autoconnect-priority = 1;
          interface-name = "cdc-wdm0";
        };
        gsm = {
          apn = "gprs.swisscom.ch";
          number = "*99#";
          # Flag value 4 = NM_SETTING_SECRET_FLAG_NOT_REQUIRED (no password/PIN needed).
          password-flags = "4";
          pin-flags = "4";
        };
        ipv4 = {
          # Automatically obtain IP configuration from cellular network.
          method = "auto";
        };
        ipv6 = {
          # Automatically obtain IPv6 configuration from cellular network.
          method = "auto";
          # Generate IPv6 addresses using stable algorithm (consistent but privacy-preserving).
          addr-gen-mode = "stable-privacy";
        };
        # PPP section required for GSM connections (using defaults).
        ppp = {};
        # No proxy configuration needed.
        proxy = {};
      };
    };

    systemd.units.ModemManager.enable = true;
    systemd.services.ModemManager = {
      aliases = ["dbus-org.freedesktop.ModemManager1.service"];
      wantedBy = ["NetworkManager.service"];
      partOf = ["NetworkManager.service"];
      after = ["NetworkManager.service"];
    };
    systemd.services."enable-wwan" = {
      description = "Enable WWAN radio at boot";
      after = ["NetworkManager.service"];
      wants = ["NetworkManager.service"];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.networkmanager}/bin/nmcli radio wwan on";
      };
      wantedBy = ["multi-user.target"];
    };

    services.openssh.enable = true;
    users.users.root = {
      openssh.authorizedKeys.keys = lib.splitString "\n" (builtins.readFile ../../files/ssh.pub);
    };

    system.stateVersion = "25.05";
  };

  hm.home.stateVersion = "25.05";
}
