{
  pkgs,
  ...
}: {
  "apple-color-emoji" = pkgs.callPackage ./overlays/apple-color-emoji {};
  "apple-fonts" = pkgs.callPackage ./overlays/apple-fonts {};
}