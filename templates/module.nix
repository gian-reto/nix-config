{
  lib,
  pkgs,
  config,
  inputs,
  osConfig,
  hmConfig,
  ...
}: {
  # TODO: Replace `mymodule` with the actual module name, and replace the
  # Placeholder description.

  options.mymodule.enable = lib.mkOption {
    description = ''
      Whether to enable mymodule features.
    '';
    type = lib.types.bool;
    default = false;
    example = true;
  };

  config = lib.mkIf config.mymodule.enable {
    # TODO: Toggle features or options that are specific to this module.

    # Example: Enable the `tlp` feature from `modules/features/tlp.nix`:
    #
    # features.tlp.enable = true;
  };
}
