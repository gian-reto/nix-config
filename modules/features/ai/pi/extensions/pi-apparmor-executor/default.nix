{
  lib,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation {
  pname = "pi-apparmor-executor";
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
    description = "Run Pi built-in tool operations under a configured AppArmor profile";
    platforms = lib.platforms.linux;
  };
}
