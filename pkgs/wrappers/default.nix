{wlib}:
builtins.mapAttrs (_: module: (wlib.evalModule module).config) {
  herdr = ./herdr.nix;
  pi = ./pi.nix;
}
