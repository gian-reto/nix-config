{
  pkgs,
  inputs,
  lib,
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
        scale = 1.0;
        refreshRate = 60;
      };
    };
  };
  laptop.enable = true;

  # Machine-specific configuration.
  os = rec {
    nixpkgs.config = {
      allowUnfree = true;
      allowUnfreePredicate = _: true;
    };

    nixos-x13s = {
      enable = true;

      kernel = "jhovold";
      bluetoothMac = "E4:38:83:2F:84:FA";
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

    # System wide packages.
    environment.systemPackages = with pkgs; [
      # See: https://github.com/jhovold/linux/wiki/X13s#userspace-dependencies.
      alsa-ucm-conf
      libcamera
      libqmi

      # Some additional tools.
      glxinfo
      pciutils
      modemmanager
      vulkan-tools
    ];

    # Fingerprint.
    services.fprintd.enable = true;
    services.fprintd.tod.enable = true;
    services.fprintd.tod.driver = pkgs.libfprint-2-tod1-goodix;

    # Network manager modemmanager setup.
    services.udev.packages = [ pkgs.modemmanager ];
    services.dbus.packages = [ pkgs.modemmanager ];
    systemd.packages = [ pkgs.modemmanager ];

    systemd.units.ModemManager.enable = true;
    networking.networkmanager = {
      enable = true;

      fccUnlockScripts = [
        {
          id = "105b:e0c3";
          path = "${pkgs.modemmanager}/share/ModemManager/fcc-unlock.available.d/105b:e0c3";
        }
      ];
    };
    systemd.services.ModemManager = {
      aliases = [ "dbus-org.freedesktop.ModemManager1.service" ];
      wantedBy = [ "NetworkManager.service" ];
      partOf = [ "NetworkManager.service" ];
      after = [ "NetworkManager.service" ];
    };

    # Fix the bluetooth service. `bluetooth-x13s-mac.service` (from
    # `nixos-x13s`) seems to be broken.
    systemd.services = {
      bluetooth-x13s-mac = {
        enable = lib.mkForce false;
      };
      bluetooth-x13s-mac-fix = {
        enable = lib.mkDefault true;

        description = "Fix bluetooth device MAC address";
        unitConfig = {
          Type = "oneshot";
        };
        serviceConfig = {
          User = "root";
          RemainAfterExit = true;
        };
        wantedBy = [ "multi-user.target" ];
        after = [ "multi-user.target" "bluetooth.service" ];
        script = ''
          count=0
          while true; do
            count=$((count + 1))

            if test $count -ge 5; then
                echo "Bluetooth MAC address not correct after $count attempts"
                break
            fi

            mac=$(${pkgs.bluez}/bin/hciconfig | grep "BD Address" | ${pkgs.gawk}/bin/awk '{ print $3 }')
            if [ "$mac" != "${nixos-x13s.bluetoothMac}" ]; then
              echo "Bluetooth MAC address is incorrect. Fixing..."
              echo "Blocking bluetooth device..."
              ${pkgs.util-linux}/bin/rfkill block bluetooth
              echo "Unblocking bluetooth device..."
              ${pkgs.util-linux}/bin/rfkill unblock bluetooth
              echo "Setting bluetooth MAC address..."
              ${pkgs.util-linux}/bin/script -c '${pkgs.bluez}/bin/btmgmt --index 0 public-addr ${nixos-x13s.bluetoothMac}'
            else
              echo "Bluetooth MAC address correct after $count attempts"
              break
            fi

            sleep $((2 + (count * 3)))
          done
        '';
      };
    };

    # Enable GPU acceleration.
    hardware.opengl = {
      enable = true;
      
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

    system.stateVersion = "24.05";
  };

  hm.home.stateVersion = "24.05";
}