{lib, ...}: {
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
}