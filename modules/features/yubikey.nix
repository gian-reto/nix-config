{
  config,
  lib,
  pkgs,
  ...
}: {
  options.features.yubikey.enable = lib.mkOption {
    description = ''
      Whether to enable YubiKey stuff.
    '';
    type = lib.types.bool;
    default = false;
    example = true;
  };

  config.hm = lib.mkIf config.features.yubikey.enable {
    systemd.user.services.yubikey-touch-detector = {
      Unit.Description = "YubiKey touch detector";
      Install.WantedBy = ["graphical-session.target"];
      Service.ExecStart = lib.getExe pkgs.yubikey-touch-detector;
    };
  };
}
