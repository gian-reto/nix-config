{
  fetchFromGitHub,
  lib,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation {
  pname = "pi-herdr-subagents";
  version = "0.1.0-unstable-2026-09-01";

  src = fetchFromGitHub {
    owner = "modem-dev";
    repo = "pi-herdr-subagents";
    rev = "b6987324284b1fa22b2eb9f0effaf956ada27333";
    hash = "sha256-c8zNMN5624hvGckWZDtQ5pnfxrnYDuB477xdlbbsPzk=";
  };

  patches = [./pi-herdr-subagents-permission-forwarding.patch];

  postPatch = ''
    substituteInPlace index.ts subagent-done.ts package.json \
      --replace-fail '@mariozechner/pi-coding-agent' '@earendil-works/pi-coding-agent' \
      --replace-fail '@mariozechner/pi-tui' '@earendil-works/pi-tui' \
      --replace-fail '@sinclair/typebox' 'typebox'
    substituteInPlace src/messages.ts \
      --replace-fail '@mariozechner/pi-coding-agent' '@earendil-works/pi-coding-agent' \
      --replace-fail '@mariozechner/pi-tui' '@earendil-works/pi-tui'
    rm package-lock.json
  '';

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out"
    cp -R ./. "$out/"

    runHook postInstall
  '';

  meta = {
    description = "Interactive Pi subagent orchestration in Herdr panes";
    homepage = "https://github.com/modem-dev/pi-herdr-subagents";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
}
