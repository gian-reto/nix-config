{
  config,
  lib,
  pkgs,
  ...
}: {
  osModules = [
    # inputs.disko.nixosModules.disko
    # ./disk-configuration.nix
    # ./hardware-configuration.nix
  ];

  # Enable my modules!
  # features.sops.enable = true;

  os = {
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
      allowedTCPPorts = [22]; # SSH access.
    };

    # VM configuration for testing and development.
    virtualisation.vmVariant = {modulesPath, ...}: {
      imports = [(modulesPath + "/profiles/qemu-guest.nix")]; # Optimize for QEMU VMs.

      virtualisation = {
        cores = 4;
        diskSize = 10240; # 10GB disk.
        memorySize = 1024 * 8; # 8GB RAM.

        # Disable qemu graphics so it just uses the same terminal it was started from.
        graphics = false;

        forwardPorts = [
          {
            from = "host";
            host.port = 2222;
            guest.port = 22;
          }
        ];

        sharedDirectories = {
          age = {
            # Passed by the `deploy.sh` script.
            source = "$VM_AGE_KEY_DIR";
            target = "/home/${config.hmUsername}/.config/sops/age";
            securityModel = "mapped-xattr";
          };
        };
      };

      # Make sure to set correct permissions, because we mount into the home
      # directory of the user, and `.config` is not created at that point, which
      # would break `home-manager`.
      systemd.services."vm-fix-config-ownership" = let
        user = config.hmUsername;
        group = "users";
        xdgConfigHome = "/home/${user}/.config";
      in {
        description = "Fix ownership of ${xdgConfigHome} and subdirectories due to VM shared directory mount";
        before = ["home-manager-${user}.service"];
        wantedBy = ["home-manager-${user}.service"];

        serviceConfig = {
          Type = "oneshot";
          ExecStart = ''
            ${pkgs.coreutils}/bin/chown ${user}:${group} ${xdgConfigHome} ${xdgConfigHome}/sops ${xdgConfigHome}/sops/age
            ${pkgs.coreutils}/bin/chmod 755 ${xdgConfigHome} ${xdgConfigHome}/sops ${xdgConfigHome}/sops/age
          '';
        };
      };

      # Set `initialPassword`, as this is a testing VM.
      users.users."${config.hmUsername}" = {
        initialPassword = "test";
      };

      services.qemuGuest.enable = true;
    };

    system.stateVersion = "25.11";
  };

  hm.home.stateVersion = "25.11";
}
