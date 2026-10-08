{lib, ...}: {
  imports = [
    ./herdr.nix
    ./pi
  ];

  options.features.ai.enable = lib.mkOption {
    description = ''
      Whether to enable the Pi and Herdr AI tooling stack.
    '';
    type = lib.types.bool;
    default = false;
    example = true;
  };
}
