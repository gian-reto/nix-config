{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  zen-browser = inputs.zen-browser.packages.${pkgs.system}.default;
in {
  options.features.zen-browser.enable = lib.mkOption {
    description = ''
      Whether to enable Zen Browser.
    '';
    type = lib.types.bool;
    default = false;
    example = true;
  };

  config.hm = lib.mkIf config.features.zen-browser.enable {
    home.packages = [
      zen-browser
    ];
  };
}
