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
  gui.enable = true;
  laptop.enable = true;

  # Enable & configure individual features.
  features = {
    desktop.monitors = {
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
    nixpkgs.config = {
      allowUnfree = true;
      allowUnfreePredicate = _: true;
    };

    boot = {
      initrd.systemd.enable = true;
      blacklistedKernelModules = ["amdxdna"];
      loader = {
        systemd-boot = {
          enable = true;
          consoleMode = "max";
        };
        efi.canTouchEfiVariables = true;
      };
    };

    # Not needed, as `discard=async` is enabled by default for btrfs (https://wiki.archlinux.org/title/Btrfs#SSD_TRIM).
    services.fstrim.enable = false;

    # System wide packages.
    environment = {
      systemPackages = with pkgs; [
        # Some additional tools.
        mesa-demos
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
    powerManagement.powertop.enable = false;
    services.tlp = {
      enable = true;

      settings = import ./tlp.nix;
    };

    # Sleep.
    services.logind.settings.Login = {
      # Suspend first then hibernate when closing the lid.
      HandleLidSwitch = "suspend-then-hibernate";

      # Hibernate on power button pressed
      HandlePowerKey = "hibernate";
      HandlePowerKeyLongPress = "poweroff";
    };
    # Delay for hibernation.
    systemd.sleep.settings.Sleep = {
      HibernateDelaySec = "15m";
      HibernateOnACPower = "no";
      # Deep sleep is not supported on this device.
      MemorySleepMode = "s2idle";
      SuspendState = "mem";
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

      networkmanager = {
        wifi.powersave = true;

        # Automatically switch between WiFi and WWAN: disable WWAN when WiFi
        # is available, enable it as a fallback when WiFi drops.
        dispatcherScripts = [
          {
            source = pkgs.writeShellScript "wifi-wwan-switch" ''
              # See `nmcli dev`.
              WIFI_IFACE="wlp1s0"

              wifi_connected() {
                ${pkgs.networkmanager}/bin/nmcli -t -f DEVICE,STATE dev 2>/dev/null \
                  | grep -q "^''${WIFI_IFACE}:connected"
              }

              wwan_radio_off() {
                [ "$(${pkgs.networkmanager}/bin/nmcli -t -f WWAN radio 2>/dev/null)" = "disabled" ]
              }

              case "$2" in
                up)
                  if [ "$1" = "$WIFI_IFACE" ] && wifi_connected; then
                    ${pkgs.networkmanager}/bin/nmcli radio wwan off
                  fi
                  ;;
                down)
                  if [ "$1" = "$WIFI_IFACE" ]; then
                    ${pkgs.networkmanager}/bin/nmcli radio wwan on
                  fi
                  ;;
                connectivity-change)
                  # Safety net for resume from suspend: enable WWAN if WiFi has
                  # not reconnected and the WWAN radio is currently off.
                  if wwan_radio_off && ! wifi_connected; then
                    ${pkgs.networkmanager}/bin/nmcli radio wwan on
                  fi
                  ;;
              esac
            '';
            type = "basic";
          }
        ];

        ensureProfiles.profiles.swisscom = {
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
    };

    # `networking.modemmanager.enable` installs ModemManager but does not pull it
    # into the boot sequence or wire it up to NetworkManager.
    systemd.units.ModemManager.enable = true;
    systemd.services.ModemManager = {
      aliases = ["dbus-org.freedesktop.ModemManager1.service"];

      after = ["NetworkManager.service"];
      partOf = ["NetworkManager.service"];
      wantedBy = ["NetworkManager.service"];
    };

    # Service to fix the Quectel EM05-G modem after suspend / hibernate.
    systemd.services."restart-wwan" = {
      description = "Restart ModemManager after suspend/hibernate";

      after = [
        "suspend.target"
        "hibernate.target"
        "suspend-then-hibernate.target"
      ];
      wantedBy = [
        "suspend.target"
        "hibernate.target"
        "suspend-then-hibernate.target"
      ];

      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.systemd}/bin/systemctl restart ModemManager.service";
      };
    };

    services.openssh.enable = true;
    users.users.root = {
      openssh.authorizedKeys.keys = lib.splitString "\n" (builtins.readFile ../../files/ssh.pub);
    };

    system.stateVersion = "25.05";
  };

  hm.home.stateVersion = "25.05";
}
