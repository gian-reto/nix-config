{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: {
  osModules = [
    inputs.nix-services.nixosModules.default
    inputs.disko.nixosModules.disko
    ./disk-configuration.nix
    ./hardware-configuration.nix
  ];

  os = {
    nixpkgs.config = {
      allowUnfree = true;
      allowUnfreePredicate = _: true;
    };

    # Enable services from `nix-services`.
    homelabServices = {
      enable = true;
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
      # Enable `swraid` to use `mdadm`.
      swraid.enable = true;
    };

    networking = {
      hostName = "trantor";
      networkmanager.enable = true;
    };

    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "prohibit-password";
      };
    };

    users.users.root = {
      openssh.authorizedKeys.keys = lib.splitString "\n" (builtins.readFile ../../files/ssh.pub);
    };

    networking.firewall = {
      enable = true;
      allowedTCPPorts = [
        22 # SSH access.
        443 # HTTPS.
      ];
    };

    # Logging & crash handling.
    boot.kernelModules = ["iTCO_wdt" "iTCO_vendor_support"]; # Intel watchdog drivers.
    # Allow clean shutdowns to disable the watchdog.
    boot.extraModprobeConfig = ''
      options iTCO_wdt nowayout=1
      options e1000e SmartPowerDownEnable=0
    '';
    boot.kernelParams = [
      "pcie_aspm=off"
      "pcie_aspm.policy=performance" # Probably useless with `pcie_aspm=off`, but whatever.
      "pcie_port_pm=off" # Disable PCIe port power management.
      "pci=noaer"
      "nmi_watchdog=1"
      "panic=10" # Reboot 10 seconds after a panic.
      "softlockup_panic=1"
      "hardlockup_panic=1"
      "hung_task_panic=1"
    ];
    boot.kernel.sysctl = {
      "kernel.panic_on_oops" = 1;
      "kernel.watchdog" = 1;
    };

    # Network connectivity check script for watchdogd.
    environment.systemPackages = let
      logInfo = message: "echo \"${message}\" | /run/current-system/sw/bin/systemd-cat -t watchdog-check-network -p info";
      logError = message: "echo \"${message}\" | /run/current-system/sw/bin/systemd-cat -t watchdog-check-network -p err";
    in [
      (pkgs.writeShellScriptBin "watchdog-check-network" ''
        #!/usr/bin/env bash
        set -euo pipefail

        ${logInfo "Checking network connectivity..."}

        if /run/current-system/sw/bin/ping -c 3 -W 5 192.168.20.1; then
          ${logInfo "Network connectivity is OK."}
          exit 0
        else
          ${logError "Network connectivity check failed!"}
          exit 1
        fi
      '')
    ];

    services.watchdogd = {
      enable = true;

      package = pkgs.watchdogd.overrideAttrs (oldAttrs: {
        configureFlags =
          (oldAttrs.configureFlags or [])
          ++ [
            "--with-generic"
            "--with-loadavg"
            "--with-meminfo"
            "--with-filenr"
          ];
      });

      settings = {
        "device /dev/watchdog" = {
          timeout = 30; # Hardware watchdog timeout in seconds.
          interval = 10; # Ping interval in seconds.
          safe-exit = true; # Disable watchdog on clean exit.
        };
        # Network connectivity monitor.
        "generic /run/current-system/sw/bin/watchdog-check-network" = {
          enabled = true;
          interval = 900; # Check every 15 minutes.
          timeout = 60; # Allow up to 60 seconds for the check to complete.
          critical = 1; # Trigger reboot on failure.
        };
        loadavg = {
          enabled = true;

          interval = 60;
          warning = 20.0; # ~ 1.0 × 20 threads (i5-13600K).
          critical = 40.0; # ~ 2.0 × 20 threads (i5-13600K), will trigger reboot.
          logmark = true;
        };
        meminfo = {
          enabled = true;

          interval = 60;
          warning = 0.85; # Warning at 85% memory usage.
          critical = 0.95; # Critical at 95% memory usage (will trigger reboot).
          logmark = true;
        };
        filenr = {
          enabled = true;

          logmark = true; # Log file descriptor usage.
        };

        # Track watchdog reset reasons.
        reset-reason.file = "/var/lib/misc/watchdogd.state";
      };
    };

    # Create directory for watchdog state file.
    systemd.tmpfiles.rules = [
      "d /var/lib/misc 0755 root root -"
    ];

    # Disable hardware offload features and increase ring buffers on Intel I219-V (e1000e) to fix hangs.
    systemd.services.disable-e1000e-offload = let
      script = pkgs.writeShellScript "disable-e1000e-offload" ''
        set -euo pipefail

        # Increase RX/TX ring buffers to maximum to prevent buffer overruns.
        ${pkgs.ethtool}/bin/ethtool -G enp0s31f6 rx 4096 tx 4096
        # Disable hardware offload features that trigger I219-V hardware bugs.
        ${pkgs.ethtool}/bin/ethtool -K enp0s31f6 gso off gro off tso off tx off rx off rxvlan off txvlan off sg off
      '';
    in {
      description = "Apply Intel I219-V workarounds (disable offloads, increase ring buffers)";
      wantedBy = ["multi-user.target"];
      after = ["network-pre.target"];
      before = ["network.target"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = script;
      };
    };

    # VM configuration for testing and development.
    virtualisation.vmVariant = {modulesPath, ...}: {
      imports = [(modulesPath + "/profiles/qemu-guest.nix")]; # Optimize for QEMU VMs.

      virtualisation = {
        cores = 4;
        diskSize = 1024 * 80; # 80GB disk.
        memorySize = 1024 * 8; # 8GB RAM.

        # Disable qemu graphics so it just uses the same terminal it was started from.
        graphics = false;

        forwardPorts = [
          {
            from = "host";
            host.port = 2222;
            guest.port = 22;
          }
          {
            from = "host";
            host.port = 8443;
            guest.port = 443;
          }
        ];

        sharedDirectories = {
          age = {
            # Passed by the `deploy.sh` script.
            source = "$VM_AGE_KEY_DIR";
            target = "/var/lib/sops-nix";
          };
        };
      };

      # Enable VM-specific overrides in `homelabServices`.
      homelabServices.isVM = true;

      # Ensure correct permissions on the `age` key file.
      systemd.tmpfiles.rules = [
        "z /var/lib/sops-nix/key.txt 0600 root root -"
      ];

      # Set `initialPassword`, as this is a testing VM.
      users.users."${config.hmUsername}" = {
        initialPassword = "test";
      };

      services.qemuGuest.enable = true;
    };

    system.stateVersion = "25.05";
  };

  hm.home.stateVersion = "25.05";
}
