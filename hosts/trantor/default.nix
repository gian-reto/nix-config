{lib, ...}: {
  osModules = [
    # inputs.disko.nixosModules.disko
    # ./disk-configuration.nix
    # ./hardware-configuration.nix
  ];

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

        forwardPorts = [
          {
            from = "host";
            host.port = 2222;
            guest.port = 22;
          }
        ];
      };

      services.qemuGuest.enable = true;
    };

    system.stateVersion = "25.11";
  };

  hm.home.stateVersion = "25.11";
}
