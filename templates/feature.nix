{
  lib,
  pkgs,
  config,
  inputs,
  osConfig,
  hmConfig,
  ...
}: {
  # TODO: Replace `myfeature` with the actual feature name, and replace the
  # Placeholder description.

  options.features.myfeature.enable = lib.mkOption {
    description = ''
      Whether to enable myfeature.
    '';
    type = lib.types.bool;
    default = false;
    example = true;
  };

  config.os = lib.mkIf config.features.myfeature.enable {
    # TODO: Add NixOS options, or remove this block if not needed.
  };

  config.hm = lib.mkIf config.features.myfeature.enable {
    # TODO: Add Home Manager options, or remove this block if not needed.
  };
}
