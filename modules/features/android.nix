{
  lib,
  config,
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
    programs = {
      adb.enable = true;
    };
  };
}
