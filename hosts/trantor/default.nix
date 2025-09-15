{
  config,
  inputs,
  lib,
  ...
}: {
  osModules = [
    inputs.nix-services.nixosModules.default
    # inputs.disko.nixosModules.disko
    # ./disk-configuration.nix
    # ./hardware-configuration.nix
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

    system.stateVersion = "25.11";
  };

  hm.home.stateVersion = "25.11";
}
