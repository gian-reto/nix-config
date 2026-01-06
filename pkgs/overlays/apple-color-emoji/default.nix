{
  lib,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation rec {
  pname = "apple-color-emoji";
  version = "18.4";
  meta = {
    description = "Apple Color Emoji font";
    homepage = "https://developer.apple.com/fonts/";
    license = lib.licenses.unfree;
  };

  src = builtins.fetchurl {
    url = "https://github.com/samuelngs/apple-emoji-linux/releases/download/v${version}/AppleColorEmoji.ttf";
    sha256 = "sha256:a4fd077bd11437b4940d8cf08f4084e1edfd4ae359f92573ec576652f885eabd";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/fonts/truetype
    cp $src $out/share/fonts/truetype/AppleColorEmoji.ttf

    runHook postInstall
  '';
}
