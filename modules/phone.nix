{
  lib,
  config,
  ...
}: {
  options.phone.enable = lib.mkOption {
    description = ''
      Whether to enable features specific to phones.
    '';
    type = lib.types.bool;
    default = false;
    example = true;
  };

  config = lib.mkIf config.phone.enable {
    features.flatpak.enable = true;
    features.ghostty.enable = true;
    features.git.enable = true;
    features.gpg.enable = true;
    features.op.enable = true;
    features.ssh.enable = true;
    features.vpn.enable = true;
    features.yubikey.enable = true;
  };
}
