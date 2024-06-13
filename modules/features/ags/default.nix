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

  # config.hmModules = [inputs.ags.homeManagerModules.default];

  # config.hm = lib.mkIf config.features.ags.enable {
  #   # TODO: See: https://github.com/Aylur/dotfiles/blob/main/home-manager/ags.nix.
  # };
}