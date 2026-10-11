{
  lib,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation {
  pname = "pi-herdr-permissions";
  version = (builtins.fromJSON (builtins.readFile ./package.json)).version;

  src = lib.cleanSourceWith {
    src = ./.;
    filter = path: type:
      builtins.baseNameOf path
      != "node_modules"
      && lib.cleanSourceFilter path type;
  };

  dontBuild = true;
  dontFixup = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    cp -r . "$out/"
    runHook postInstall
  '';

  meta = {
    description = "Report visible Pi permission dialogs as blocked in Herdr";
    platforms = lib.platforms.unix;
  };
}
