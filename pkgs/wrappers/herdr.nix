{
  lib,
  pkgs,
  wlib,
  ...
}: {
  imports = [
    wlib.modules.default
    ./mixins/with-op-run.nix
  ];

  config.package = lib.mkDefault pkgs.herdr;
}
