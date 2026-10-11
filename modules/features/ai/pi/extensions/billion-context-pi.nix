{
  fetchurl,
  gzip,
  gnutar,
  lib,
  stdenvNoCC,
}: let
  # Note: When upgrading the version, make sure to re-check the tools provided
  # by this extension and update ../permissions.nix accordingly.
  version = "0.1.83";
  source = fetchurl {
    url = "https://registry.npmjs.org/billion-context-pi/-/billion-context-pi-${version}.tgz";
    hash = "sha512-122CcPmZvC5Yqqbj75UMppOFlkdAN8kbzvJ4OugV6xBPW6wbiHbaZ9YDYWQwDy4hJ/Vc98eOREGkWLWKflbnZw==";
  };
in
  stdenvNoCC.mkDerivation {
    pname = "billion-context-pi";
    inherit version;

    dontUnpack = true;
    strictDeps = true;
    nativeBuildInputs = [
      gzip
      gnutar
    ];

    installPhase = ''
      runHook preInstall

      mkdir -p "$out"
      tar --extract --gzip --file='${source}' --directory="$out" --strip-components=1

      runHook postInstall
    '';

    meta = {
      description = "Model-driven context management extension for Pi";
      homepage = "https://github.com/ranxianglei/billion-context-pi";
      license = lib.licenses.mit;
      platforms = lib.platforms.all;
    };
  }
