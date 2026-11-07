{
  config,
  lib,
  pkgs,
  wlib,
  ...
}: let
  pathsOption = description:
    lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      inherit description;
    };
in {
  imports = [
    wlib.modules.default
    ./mixins/with-op-run.nix
  ];

  options = {
    extensions = pathsOption "Extensions loaded for every Pi invocation.";
    prompts = pathsOption "Additional prompt-template paths.";
    rootExtensions = pathsOption "Extensions omitted for managed subagent invocations.";
    skills = pathsOption "Additional skill paths.";
  };

  config = {
    package = lib.mkDefault pkgs.pi-coding-agent;
    binName = "pi";
    flags = {
      "--extension" = config.extensions;
      "--prompt-template" = config.prompts;
      "--skill" = config.skills;
    };
    runShell = lib.optional (config.rootExtensions != []) ''
      if [[ "''${PI_SUBAGENT_CHILD:-0}" != 1 ]]; then
        set -- ${lib.escapeShellArgs (lib.concatMap (path: ["--extension" path]) config.rootExtensions)} "$@"
      fi
    '';
  };
}
