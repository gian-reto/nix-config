{
  config,
  lib,
  ...
}: {
  options.features.i18n.enable = lib.mkOption {
    description = ''
      Whether to enable i18n stuff.
    '';
    type = lib.types.bool;
    default = false;
    example = true;
  };

  config.os = lib.mkIf config.features.i18n.enable {
    i18n = {
      defaultLocale = lib.mkDefault "en_US.UTF-8";
      extraLocaleSettings = {
        LC_TIME = lib.mkDefault "de_CH.UTF-8";
      };
      supportedLocales = lib.mkDefault [
        "en_US.UTF-8/UTF-8"
        "de_CH.UTF-8/UTF-8"
      ];
    };
    
    time.timeZone = lib.mkDefault "Europe/Zurich";
  };
}