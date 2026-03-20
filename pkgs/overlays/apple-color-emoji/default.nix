{
  lib,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation rec {
  pname = "apple-color-emoji";
  version = "macos-26-20260219-2aa12422";
  meta = {
    description = "Apple Color Emoji font";
    homepage = "https://developer.apple.com/fonts/";
    license = lib.licenses.unfree;
  };

  src = builtins.fetchurl {
    url = "https://github.com/samuelngs/apple-emoji-ttf/releases/download/${version}/AppleColorEmoji-Linux.ttf";
    sha256 = "sha256:535a043af04706d24471059e64745bfc80d6617ada2eea3435dc5620dc0f5318";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/fonts/truetype
    cp $src $out/share/fonts/truetype/AppleColorEmoji.ttf

    runHook postInstall
  '';
}
