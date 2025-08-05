{
  pkgs,
  inputs,
  lib,
  ...
}: {
  osModules = [
    inputs.disko.nixosModules.disko
    inputs.nixos-x13s.nixosModules.default
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
  laptop.enable = true;

  # Enable individual features.
  features.distributed-builds.enable = true;

  # Machine-specific configuration.
  os = rec {
    programs = {
      light.enable = true;
    };

    nixpkgs.config = {
      allowUnfree = true;
      allowUnfreePredicate = _: true;
    };

    nixos-x13s = {
      enable = true;

      kernel = "jhovold";
      bluetoothMac = "E4:38:83:2F:84:FA";
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
    services.udev.packages = [pkgs.modemmanager];
    services.dbus.packages = [pkgs.modemmanager];
    systemd.packages = [pkgs.modemmanager];

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
      aliases = ["dbus-org.freedesktop.ModemManager1.service"];
      wantedBy = ["NetworkManager.service"];
      partOf = ["NetworkManager.service"];
      after = ["NetworkManager.service"];
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
        wantedBy = ["multi-user.target"];
        after = ["multi-user.target" "bluetooth.service"];
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

    # Fix some audio issues.
    # See: https://github.com/boletus-edulis/nix-modules/blob/b83b7d7db9c28217f798867f8751c1ed8104fa53/x13s.nix#L86.
    services.pipewire.extraConfig.pipewire = {
      "10-fix-crackling" = {
        "pulse.properties" = {
          "pulse.min.req" = "1024/48000";
          "pulse.min.frag" = "1024/48000";
          "pulse.min.quantum" = "1024/48000";
        };
      };
      "11-disable-suspend" = {
        "monitor.alsa.rules" = [
          {
            "matches" = [
              {
                # Matches all sources.
                "node.name" = "~alsa_input.*";
              }
              {
                # Matches all sinks.
                "node.name" = "~alsa_output.*";
              }
            ];
            "actions" = {
              "update-props" = {
                "session.suspend-timeout-seconds" = 0;
              };
            };
          }
        ];
      };
    };

    # Enable GPU acceleration.
    hardware.graphics = {
      enable = true;

      # From: https://github.com/LunNova/nixos-configs/blob/76ea08c9202ef77ab72eb3cd4715c28475a2667e/hosts/amayadori/x13s.nix#L236.
      package =
        ((pkgs.mesa.override {
            galliumDrivers = ["swrast" "freedreno" "zink"];
            vulkanDrivers = ["swrast" "freedreno"];
          })
          .overrideAttrs (old: {
            mesonFlags =
              old.mesonFlags
              ++ [
                "-Dgallium-vdpau=disabled"
                "-Dgallium-va=disabled"
                "-Dandroid-libbacktrace=disabled"
              ];
            postPatch = ''
              ${old.postPatch}

              mkdir -p $spirv2dxil
              touch $spirv2dxil/dummy
            '';
          }))
        .drivers;
    };

    system.stateVersion = "24.05";
  };

  hm.home.stateVersion = "24.05";
}
