{
  lib,
  pkgs,
  config,
  ...
}: {
  options.features.virtualization.enable = lib.mkOption {
    description = ''
      Whether to enable virtualization support with QEMU/KVM and libvirtd.
    '';
    type = lib.types.bool;
    default = false;
    example = true;
  };

  config.os = lib.mkIf config.features.virtualization.enable {
    # See: https://nixos.wiki/wiki/Libvirt.
    virtualisation.libvirtd = {
      enable = true;

      qemu = {
        package = pkgs.qemu_kvm;
        runAsRoot = true;
        swtpm.enable = true;
        ovmf = {
          enable = true;
          packages = [
            (pkgs.OVMF.override {
              secureBoot = true;
              tpmSupport = true;
            }).fd
          ];
        };
      };
    };

    users.users."${config.hmUsername}" = {
      extraGroups = ["libvirtd"];
    };

    programs.virt-manager.enable = true;

    networking.firewall.trustedInterfaces = [
      "virbr0"
      "br0"
    ];
  };
}
