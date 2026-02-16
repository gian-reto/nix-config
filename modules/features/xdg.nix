{
  config,
  lib,
  hmConfig,
  ...
}: {
  options.features.xdg.enable = lib.mkOption {
    description = ''
      Whether to enable some XDG directories and settings.
    '';
    type = lib.types.bool;
    default = false;
    example = true;
  };

  config.hm = lib.mkIf config.features.xdg.enable {
    xdg.userDirs = let
      home = hmConfig.home.homeDirectory;
    in {
      enable = true;
      createDirectories = true;

      desktop = "${home}/Desktop";
      documents = "${home}/Documents";
      download = "${home}/Downloads";
      music = "${home}/Music";
      pictures = "${home}/Pictures";
      publicShare = "${home}/Public";
      templates = "${home}/Templates";
      videos = "${home}/Videos";

      extraConfig = {
        CODE = "${hmConfig.home.homeDirectory}/Code";
        SCREENSHOTS = "${hmConfig.xdg.userDirs.pictures}/Screenshots";
      };
    };
  };
}
