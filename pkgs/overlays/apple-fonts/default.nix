{
  lib,
  stdenvNoCC,
  p7zip,
}:
stdenvNoCC.mkDerivation rec {
  pname = "apple-fonts";
  version = "1.0";
  meta = {
    description = "Apple San Francisco, New York fonts";
    homepage = "https://developer.apple.com/fonts/";
    license = lib.licenses.unfree;
  };

  pro = builtins.fetchurl {
    url = "https://devimages-cdn.apple.com/design/resources/download/SF-Pro.dmg";
    sha256 = "sha256-B8xljBAqOoRFXvSOkOKDDWeYUebtMmQLJ8lF05iFnXk=";
  };
  compact = builtins.fetchurl {
    url = "https://devimages-cdn.apple.com/design/resources/download/SF-Compact.dmg";
    sha256 = "sha256-L4oLQ34Epw1/wLehU9sXQwUe/LaeKjHRxQAF6u2pfTo=";
  };
  mono = builtins.fetchurl {
    url = "https://devimages-cdn.apple.com/design/resources/download/SF-Mono.dmg";
    sha256 = "sha256-Uarx1TKO7g5yVBXAx6Yki065rz/wRuYiHPzzi6cTTl8=";
  };
  ny = builtins.fetchurl {
    url = "https://devimages-cdn.apple.com/design/resources/download/NY.dmg";
    sha256 = "sha256-yYyqkox2x9nQ842laXCqA3UwOpUGyIfUuprX975OsLA=";
  };

  dontUnpack = true;
  nativeBuildInputs = [p7zip];

  installPhase = ''
    runHook preInstall

    7z x ${pro}
    cd SFProFonts
    7z x 'SF Pro Fonts.pkg'
    7z x 'Payload~'
    mkdir -p $out/fontfiles
    mv Library/Fonts/* $out/fontfiles
    cd ..

    7z x ${mono}
    cd SFMonoFonts
    7z x 'SF Mono Fonts.pkg'
    7z x 'Payload~'
    mv Library/Fonts/* $out/fontfiles
    cd ..

    7z x ${compact}
    cd SFCompactFonts
    7z x 'SF Compact Fonts.pkg'
    7z x 'Payload~'
    mv Library/Fonts/* $out/fontfiles
    cd ..

    7z x ${ny}
    cd NYFonts
    7z x 'NY Fonts.pkg'
    7z x 'Payload~'
    mv Library/Fonts/* $out/fontfiles

    mkdir -p $out/share/fonts/opentype/${pname}
    mkdir -p $out/share/fonts/truetype/${pname}
    mv $out/fontfiles/*.otf $out/share/fonts/opentype/${pname}/
    mv $out/fontfiles/*.ttf $out/share/fonts/truetype/${pname}/
    rm -rf $out/fontfiles

    runHook postInstall
  '';
}
