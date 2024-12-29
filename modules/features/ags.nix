{
  pkgs,
  config,
  lib,
  inputs,
  ...
}: {
  options.features.ags.enable = lib.mkOption {
    description = ''
      Whether to enable [ags](https://github.com/Aylur/ags).
    '';
    type = lib.types.bool;
    default = false;
    example = true;
  };

  config.hmModules = lib.mkIf config.features.ags.enable [
    inputs.ags.homeManagerModules.default
  ];

  config.hm = lib.mkIf config.features.ags.enable {
    home.packages = with pkgs; [
      bun
      dart-sass
      fd
    ];

    programs.ags = {
      enable = true;

      configDir = ../../ags;
      # See: https://aylur.github.io/ags-docs/config/home-manager.
      # extraPackages = with pkgs; [
      #   accountsservice
      # ];
    };
  };
}
