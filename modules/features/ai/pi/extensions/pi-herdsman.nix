{
  fetchurl,
  gnutar,
  gzip,
  lib,
  stdenvNoCC,
}: let
  version = "0.21.3";
  source = fetchurl {
    url = "https://registry.npmjs.org/pi-herdsman/-/pi-herdsman-${version}.tgz";
    hash = "sha512-w2WMtEKviIJulMx5uPiYrcxzQBXCpc44kUkvNoFElWrQ1//RtCT8v71j2wZkQs4z9iLH/e/G0L0MGoi8pWRF+A==";
  };
in
  stdenvNoCC.mkDerivation {
    pname = "pi-herdsman";
    inherit version;

    dontUnpack = true;
    dontConfigure = true;
    dontBuild = true;
    strictDeps = true;
    nativeBuildInputs = [
      gnutar
      gzip
    ];

    installPhase = ''
      runHook preInstall

      mkdir -p "$out"
      tar --extract --gzip --file='${source}' --directory="$out" --strip-components=1

      runHook postInstall
    '';

    meta = {
      description = "Asynchronous Pi agent orchestration in Herdr panes";
      homepage = "https://github.com/boadij/pi-herdsman";
      license = lib.licenses.asl20;
      platforms = lib.platforms.unix;
    };
  }
