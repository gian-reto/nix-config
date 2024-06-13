{
  lib,
  stdenvNoCC,
}: stdenvNoCC.mkDerivation rec {
    pname = "apple-color-emoji";
    version = "17.4";
    meta = {
      description = "Apple Color Emoji font";
      homepage = "https://developer.apple.com/fonts/";
      license = lib.licenses.unfree;
    };

    src = builtins.fetchurl {
      url = "https://github.com/samuelngs/apple-emoji-linux/releases/download/v${version}/AppleColorEmoji.ttf";
      sha256 = "sha256:1wahjmbfm1xgm58madvl21451a04gxham5vz67gqz1cvpi0cjva8";
    };

    dontUnpack = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/share/fonts/truetype
      cp $src $out/share/fonts/truetype/AppleColorEmoji.ttf

      runHook postInstall
    '';
  }