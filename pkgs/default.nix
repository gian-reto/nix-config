{pkgs, ...}: {
  "apple-color-emoji" = pkgs.callPackage ./overlays/apple-color-emoji {};
  "apple-fonts" = pkgs.callPackage ./overlays/apple-fonts {};
  "blink-mac-system-fonts" = pkgs.callPackage ./overlays/blink-mac-system-fonts {};
  "widevinecdm-aarch64" = pkgs.callPackage ./widevinecdm-aarch64 {};
}
