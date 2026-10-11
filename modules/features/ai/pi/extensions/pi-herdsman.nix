{
  fetchurl,
  gnutar,
  gzip,
  lib,
  stdenvNoCC,
}: let
  # Note: When upgrading the version, make sure to re-check the tools provided
  # by this extension and update ../permissions.nix accordingly.
  version = "0.25.1";
  source = fetchurl {
    url = "https://registry.npmjs.org/pi-herdsman/-/pi-herdsman-${version}.tgz";
    hash = "sha512-0B07XIGrsky/HzWHjD8ifjzwkYNk47X5WxsqZSVvUMeY/DCq3cXMdZCt/zOumTprPJf43Pz2V+14bl27JvSfew==";
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
