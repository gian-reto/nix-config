{
  lib,
  config,
  ...
}: {
  options.server.enable = lib.mkOption {
    description = ''
      Whether to enable features specific to servers.
    '';
    type = lib.types.bool;
    default = false;
    example = true;
  };

  config = lib.mkIf config.server.enable {
    features.nfs.enable = true;
  };
}
