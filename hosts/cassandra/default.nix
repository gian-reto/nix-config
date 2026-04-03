{
  pkgs,
  inputs,
  lib,
  ...
}: {
  osModules = [
    inputs.disko.nixosModules.disko
    inputs.x13s-nixos.nixosModules.default
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
    distributed-builds.enable = true;
  };

  # Machine-specific configuration.
  os = {
    nixpkgs.config = {
      allowUnfree = true;
      allowUnfreePredicate = _: true;
    };

    hardware.lenovo-thinkpad-x13s.enable = true;

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

    # Firmware updates.
    services.fwupd.enable = true;

    # System wide packages.
    environment.systemPackages = with pkgs; [
      # See: https://github.com/jhovold/linux/wiki/X13s#userspace-dependencies.
      alsa-ucm-conf
      libcamera
      libqmi

      # Some additional tools.
      mesa-demos
      modemmanager
      pciutils
      vulkan-tools
    ];

    # GPU stuff.
    hardware.graphics.enable = true;

    # Power management.
    services.power-profiles-daemon.enable = false;
    powerManagement.powertop.enable = false;
    services.tlp = {
      enable = true;

      settings = import ./tlp.nix;
    };

    # Fingerprint.
    services.fprintd.enable = true;
    services.fprintd.tod.enable = true;
    services.fprintd.tod.driver = pkgs.libfprint-2-tod1-goodix;

    networking = {
      hostName = "cassandra";

      # Cellular modem configuration.
      modemmanager = {
        enable = true;
        package = pkgs.modemmanager;

        fccUnlockScripts = [
          {
            id = "105b:e0c3";
            path = "${pkgs.modemmanager}/share/ModemManager/fcc-unlock.available.d/105b:e0c3";
          }
        ];
      };

      networkmanager = {
        # Automatically switch between WiFi and WWAN: disable WWAN when WiFi
        # is available, enable it as a fallback when WiFi drops.
        dispatcherScripts = [
          {
            source = pkgs.writeShellScript "wifi-wwan-switch" ''
              # See `nmcli dev`.
              WIFI_IFACE="wlP6p1s0"

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

    # Service to fix the modem after suspend / hibernate.
    systemd.services."restart-wwan" = {
      description = "Restart ModemManager after suspend/hibernate";

      after = [
        "hibernate.target"
        "suspend.target"
      ];
      wantedBy = [
        "hibernate.target"
        "suspend.target"
      ];

      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.systemd}/bin/systemctl restart ModemManager.service";
      };
    };

    services.udev.extraRules = let
      wifiMac = "00:03:7f:12:64:9f";
    in ''
      ACTION=="add", SUBSYSTEM=="net", KERNELS=="0006:01:00.0", RUN+="${pkgs.iproute2}/bin/ip link set dev $name address ${wifiMac}"
    '';

    # Fix the bluetooth service. `bluetooth-x13s-mac.service` (from
    # `nixos-x13s`) seems to be broken.
    systemd.services = {
      bluetooth-x13s-mac-fix = let
        bluetoothMac = "E4:38:83:2F:84:FA";
      in {
        enable = lib.mkDefault true;

        description = "Fix bluetooth device MAC address";
        serviceConfig = {
          RemainAfterExit = true;
          Type = "oneshot";
          User = "root";
        };
        wantedBy = ["multi-user.target"];
        after = ["multi-user.target" "bluetooth.service"];

        script = ''
          set -euo pipefail

          get_mac() {
            ${pkgs.bluez}/bin/hciconfig -a 2>/dev/null | ${pkgs.gawk}/bin/awk '/BD Address/ { print $3; exit }'
          }

          count=0
          while true; do
            count=$((count + 1))

            if test $count -ge 5; then
                echo "Bluetooth MAC address not correct after $count attempts"
                exit 1
            fi

            mac="$(get_mac || true)"
            if [ "$mac" != "${bluetoothMac}" ]; then
              echo "Bluetooth MAC address is incorrect. Fixing..."
              echo "Blocking bluetooth device..."
              ${pkgs.util-linux}/bin/rfkill block bluetooth || true
              echo "Unblocking bluetooth device..."
              ${pkgs.util-linux}/bin/rfkill unblock bluetooth || true
              echo "Setting bluetooth MAC address..."
              if ${pkgs.util-linux}/bin/script -qec '${pkgs.bluez}/bin/btmgmt --index 0 public-addr ${bluetoothMac}' /dev/null >/dev/null 2>&1; then
                echo "Bluetooth MAC address update command succeeded"
              else
                echo "Bluetooth MAC address update command failed, retrying..."
              fi
            else
              echo "Bluetooth MAC address correct after $count attempts"
              # Block device again, because we want bluetooth to be off by default.
              ${pkgs.util-linux}/bin/rfkill block bluetooth || true
              exit 0
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

    services.openssh.enable = true;
    users.users.root = {
      openssh.authorizedKeys.keys = lib.splitString "\n" (builtins.readFile ../../files/ssh.pub);
    };

    system.stateVersion = "25.11";
  };

  hm.home.stateVersion = "25.11";
}
