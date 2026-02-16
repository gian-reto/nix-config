{
  config,
  lib,
  pkgs,
  ...
}: {
  options.features.android.enable = lib.mkOption {
    description = ''
      Whether to enable android-related (dev-)features.
    '';
    type = lib.types.bool;
    default = false;
    example = true;
  };

  config.os = lib.mkIf config.features.android.enable {
    environment.systemPackages = [pkgs.android-tools];
  };
}
