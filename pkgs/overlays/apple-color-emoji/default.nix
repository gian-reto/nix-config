{
  lib,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation rec {
  pname = "apple-color-emoji";
  version = "macos-26-20260722-484daf4e";
  meta = {
    description = "Apple Color Emoji font";
    homepage = "https://developer.apple.com/fonts/";
    license = lib.licenses.unfree;
  };

  src = builtins.fetchurl {
    url = "https://github.com/samuelngs/apple-emoji-ttf/releases/download/${version}/AppleColorEmoji-Linux.ttf";
    sha256 = "sha256:e37c7af6265ac4a0af6d57bc65e86109a776d9966e8343334557f63da482516f";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/fonts/truetype
    cp $src $out/share/fonts/truetype/AppleColorEmoji.ttf

    runHook postInstall
  '';
}
