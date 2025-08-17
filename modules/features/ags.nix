{
  pkgs,
  config,
  lib,
  inputs,
  ...
}: {
  options.features.ags.enable = lib.mkOption {
    description = ''
      Whether to enable [ags](https://github.com/Aylur/ags) with the
      [adw-shell](https://gian-reto/adw-shell) configuration.
    '';
    type = lib.types.bool;
    default = false;
    example = true;
  };

  config.hm = lib.mkIf config.features.ags.enable {
    home.packages = [
      inputs.adw-shell.packages.${pkgs.system}.default
      inputs.adw-shell.packages.${pkgs.system}.ags
    ];
  };
}
