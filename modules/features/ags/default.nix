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
    # The home-manager module does not expose the astal cli to the home
    # environment.
    home.packages = [
      inputs.ags.packages.${pkgs.system}.io
    ];

    programs.ags = {
      enable = true;

      # Symlink to `~/.config/ags`.
      configDir = ./config;

      # Additional packages to add to `gjs`'s runtime.
      extraPackages = [
        inputs.ags.packages.${pkgs.system}.apps
        inputs.ags.packages.${pkgs.system}.battery
        inputs.ags.packages.${pkgs.system}.bluetooth
        inputs.ags.packages.${pkgs.system}.hyprland
        inputs.ags.packages.${pkgs.system}.mpris
        inputs.ags.packages.${pkgs.system}.network
        inputs.ags.packages.${pkgs.system}.notifd
        inputs.ags.packages.${pkgs.system}.tray
        inputs.ags.packages.${pkgs.system}.wireplumber
      ];
    };
  };
}
