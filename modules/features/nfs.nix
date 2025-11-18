{
  lib,
  pkgs,
  config,
  ...
}: {
  options.features.nfs.enable = lib.mkOption {
    description = ''
      Whether to enable NFS filesystem support for mounting NFS shares.
    '';
    type = lib.types.bool;
    default = false;
    example = true;
  };

  config.os = lib.mkIf config.features.nfs.enable {
    # Enable mounting of `nfs` shares.
    boot.supportedFilesystems = ["nfs"];
    environment.systemPackages = with pkgs; [nfs-utils];
  };
}
