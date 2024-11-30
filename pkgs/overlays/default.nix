_: prev: {
  "apple-color-emoji" = prev.callPackage ./apple-color-emoji {};
  "apple-fonts" = prev.callPackage ./apple-fonts {};
  "blink-mac-system-fonts" = prev.callPackage ./blink-mac-system-fonts {};
  # Patched `libcamera` and `wireplumber` due to signing issues.
  # See: https://github.com/NixOS/nixos-hardware/issues/1208.
  libcamera = prev.libcamera.overrideAttrs (_: {
    postFixup = ''
      ../src/ipa/ipa-sign-install.sh src/ipa-priv-key.pem $out/lib/libcamera/ipa_*.so
    '';
  });
  wireplumber = prev.wireplumber.overrideAttrs (_: {
    version = "git";
    src = prev.fetchFromGitLab {
      domain = "gitlab.freedesktop.org";
      owner = "pipewire";
      repo = "wireplumber";
      rev = "71f868233792f10848644319dbdc97a4f147d554";
      hash = "sha256-VX3OFsBK9AbISm/XTx8p05ak+z/VcKXfUXhB9aI9ev8=";
    };
  });
}
