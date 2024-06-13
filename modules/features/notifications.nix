{
  lib,
  config,
  osConfig,
  ...
}: {
  options.features.notifications.enable = lib.mkOption {
    description = ''
      Whether to enable the notification service feature.
    '';
    type = lib.types.bool;
    default = false;
    example = true;
  };

  config.hm = lib.mkIf config.features.notifications.enable {
    services.mako = {
      enable = true;

      anchor = "top-right";
      sort = "-time";
      layer = "overlay";
      markup = true;
      actions = true;
      format = "<b>%a</b>\n%b";

      backgroundColor = "#000000e6";
      textColor = "#565b66";
      width = 350;
      height = 600;
      borderSize = 0;
      borderColor = "#434852";
      borderRadius = 5;
      icons = false;
      defaultTimeout = 5000;
      ignoreTimeout = true;
      font = "${builtins.head osConfig.fonts.fontconfig.defaultFonts.sansSerif}";
      margin = "10";
      padding = "15";

      # TODO: Replace Spotify.
      extraConfig = ''
        [hidden]
        format=Hidden: %h [%t]

        [app-name=Spotify]
        icons=1
        max-icon-size=48
        padding=10
      '';
    };
  };
}