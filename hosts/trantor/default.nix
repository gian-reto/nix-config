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

  # Enable my modules!
  server.enable = true;

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
      swraid = {
        enable = true;
        # Stop `mdadm` from complaining about "Neither MAILADDR nor PROGRAM has been set.
        # This will cause the `mdmon` service to crash."
        mdadmConf = "PROGRAM ${pkgs.coreutils}/bin/true";
      };
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
    boot.extraModprobeConfig = ''
      options iTCO_wdt nowayout=1
      options e1000e SmartPowerDownEnable=0 RxIntDelay=0 TxIntDelay=0 InterruptThrottleRate=0 IntMode=1
    '';
    boot.kernelParams = [
      "pcie_aspm=off"
      "pcie_aspm.policy=performance" # Probably useless with `pcie_aspm=off`, but whatever.
      "pcie_port_pm=off" # Disable PCIe port power management.
      "pci=noaer"
      "nmi_watchdog=1"
      "intel_idle.max_cstate=1" # Prevent deep C-states that can cause I219-V issues.
      "processor.max_cstate=1"
      "panic=10" # Reboot 10 seconds after a panic.
      "softlockup_panic=1"
      "hardlockup_panic=1"
      "hung_task_panic=0"
      "hung_task_timeout_secs=300"
    ];
    boot.kernel.sysctl = {
      "kernel.panic_on_oops" = 0;
      "kernel.watchdog" = 1;
    };

    # Network connectivity check script for watchdogd.
    environment.systemPackages = let
      logInfo = message: "echo \"${message}\" | /run/current-system/sw/bin/systemd-cat -t watchdog-check-network -p info || true";
      logError = message: "echo \"${message}\" | /run/current-system/sw/bin/systemd-cat -t watchdog-check-network -p err || true";
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
          timeout = 120; # Hardware watchdog timeout in seconds.
          interval = 30; # Ping interval in seconds.
          safe-exit = true; # Disable watchdog on clean exit.
        };
        # Network connectivity monitor.
        "generic /run/current-system/sw/bin/watchdog-check-network" = {
          # Disabled for now; Causes reboot loop issues.
          enabled = false;

          interval = 900; # Check every 15 minutes.
          timeout = 60; # Allow up to 60 seconds for the check to complete.
          critical = 1; # Trigger reboot on failure.
        };
        loadavg = {
          enabled = false;

          interval = 60;
          warning = 20.0; # ~ 1.0 × 20 threads (i5-13600K).
          critical = 40.0; # ~ 2.0 × 20 threads (i5-13600K), will trigger reboot.
          logmark = true;
        };
        meminfo = {
          enabled = false;

          interval = 60;
          warning = 0.85; # Warning at 85% memory usage.
          critical = 0.95; # Critical at 95% memory usage (will trigger reboot).
          logmark = true;
        };
        filenr = {
          enabled = false;
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

    # Force PCIe power control to "on" for MEI device to prevent I219-V hangs.
    systemd.services.fix-i219-power-control = {
      description = "Force MEI PCIe power control to 'on' for I219-V stability";
      wantedBy = ["multi-user.target"];
      after = ["multi-user.target"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.bash}/bin/bash -c 'echo on > /sys/bus/pci/devices/0000:00:16.0/power/control'";
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
