{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  efiArch = pkgs.stdenv.hostPlatform.efiArch;
  kernel = "${config.boot.kernelPackages.kernel}/${config.system.boot.loader.kernelFile}";
  initrd = "${config.system.build.initialRamdisk}/${config.system.boot.loader.initrdFile}";
  dtb = "${config.hardware.deviceTree.package}/${config.hardware.deviceTree.name}";
  toplevel = config.system.build.toplevel;

  kernelParams = "init=${toplevel}/init " + lib.concatStringsSep " " config.boot.kernelParams;

  loaderEntry = pkgs.writeText "nixos.conf" ''
    title NixOS Installer
    linux /EFI/nixos/kernel
    initrd /EFI/nixos/initrd
    devicetree /EFI/nixos/dtb
    options ${kernelParams}
  '';
in {
  imports = [
    "${inputs.nixpkgs}/nixos/modules/image/repart.nix"
    inputs.nixos-hardware-x13s.nixosModules.lenovo-thinkpad-x13s
  ];

  nixpkgs.config.allowUnfree = true;
  nixpkgs.hostPlatform = "aarch64-linux";

  # Disable ZFS to avoid build failures on aarch64 (not needed for installation).
  nixpkgs.overlays = [
    (_: super: {
      zfs = super.zfs.overrideAttrs (_: {
        meta.platforms = [];
      });
      makeModulesClosure = x: super.makeModulesClosure (x // {allowMissing = true;});
    })
  ];

  # Disable all bootloader installation (we construct the ESP manually via
  # image.repart).
  boot.loader.grub.enable = false;

  boot = {
    initrd = {
      systemd.enable = true;
      systemd.tpm2.enable = false;
      systemd.emergencyAccess = true;

      availableKernelModules = [
        "nvme"
        "usb_storage"

        "dwc3-qcom"
        "dwc3"
        "i2c-core"
        "i2c-hid-of"
        "i2c-hid"
        "i2c-qcom-geni"
        "phy-qcom-qmp-combo"
        "phy-qcom-qmp-pcie"
        "phy-qcom-qmp-usb"
        "phy-qcom-snps-femto-v2"
        "phy-qcom-usb-hs"
        "xhci-plat-hcd"
      ];

      kernelModules = [];
    };

    kernelParams = [
      "clk_ignore_unused"
      "pd_ignore_unused"
      "arm64.nopauth"
      "cma=128M"
      "usbcore.autosuspend=-1"
    ];

    kernelModules = [];
    extraModulePackages = [];
  };

  hardware = {
    enableAllFirmware = true;
    firmware = [pkgs.linux-firmware];

    deviceTree = {
      enable = true;
      name = "qcom/sc8280xp-lenovo-thinkpad-x13s.dtb";
    };
  };

  systemd.tpm2.enable = false;

  # Pre-authorize SSH keys for remote access during installation.
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
  };
  users.users.root = {
    initialHashedPassword = "";
    openssh.authorizedKeys.keys = lib.splitString "\n" (builtins.readFile ../../files/ssh.pub);
  };

  # Networking.
  networking = {
    hostName = "cassandra-installer";
    networkmanager.enable = true;
  };

  services.journald.storage = "volatile";

  # Installation tools.
  environment.systemPackages = with pkgs; [
    disko
    git
    rsync
  ];

  documentation.enable = false;
  nix.settings.experimental-features = ["nix-command" "flakes"];

  fileSystems."/" = {
    device = "/dev/disk/by-label/installer";
    fsType = "ext4";
  };

  # Build a raw disk image using systemd-repart (no VM / KVM needed).
  image.repart = {
    name = "cassandra-installer";
    mkfsOptions.ext4 = ["-L" "installer"];
    partitions = {
      "10-esp" = {
        contents = {
          "/EFI/BOOT/BOOT${lib.toUpper efiArch}.EFI".source = "${pkgs.systemd}/lib/systemd/boot/efi/systemd-boot${efiArch}.efi";
          "/EFI/nixos/kernel".source = kernel;
          "/EFI/nixos/initrd".source = initrd;
          "/EFI/nixos/dtb".source = dtb;
          "/loader/entries/nixos.conf".source = loaderEntry;
        };
        repartConfig = {
          Type = "esp";
          Format = "vfat";
          SizeMinBytes = "512M";
        };
      };
      "20-root" = {
        storePaths = [toplevel];
        repartConfig = {
          Type = "root";
          Format = "ext4";
          Label = "root";
          Minimize = "guess";
          GrowFileSystem = true;
        };
      };
    };
  };

  system.stateVersion = "25.11";
}
