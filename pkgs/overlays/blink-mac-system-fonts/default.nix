{
  lib,
  stdenvNoCC,
  unzip,
  p7zip
}: stdenvNoCC.mkDerivation rec {
    pname = "blink-mac-system-font";
    version = "1.0";
    meta = {
      description = "BlinkMacSystemFont for use in web browsers";
      homepage = "https://developer.apple.com/fonts/";
      license = lib.licenses.unfree;
    };

    src = builtins.fetchurl {
      url = "https://github.com/aliifam/BlinkMacSystemFont/archive/401da13240db729268c7c8c59449debcf1bddd78.zip";
      sha256 = "sha256-MazOkmti/FSPspkxbvSmcBL5sCduX9p1lIdL+OVdiAY=";
    };

    dontUnpack = true;
    nativeBuildInputs = [ p7zip ];

    installPhase = ''
      runHook preInstall

      7z x ${src} -y
      mkdir -p $out/fontfiles
      mv BlinkMacSystemFont-401da13240db729268c7c8c59449debcf1bddd78/otf/* $out/fontfiles
      mv BlinkMacSystemFont-401da13240db729268c7c8c59449debcf1bddd78/ttf/* $out/fontfiles
      rm -rf BlinkMacSystemFont-401da13240db729268c7c8c59449debcf1bddd78

      mkdir -p $out/share/fonts/opentype/${pname} 
      mkdir -p $out/share/fonts/truetype/${pname}
      mv $out/fontfiles/*.otf $out/share/fonts/opentype/${pname}/
      mv $out/fontfiles/*.ttf $out/share/fonts/truetype/${pname}/
      rm -rf $out/fontfiles

      runHook postInstall
    '';
  }