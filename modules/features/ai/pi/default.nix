{
  config,
  inputs,
  lib,
  osConfig,
  pkgs,
  ...
}: let
  deviceIdentifierHash = builtins.hashString "sha256" "pi:${config.hmUsername}@${osConfig.networking.hostName}";
  deviceIdentifier = "${builtins.substring 0 8 deviceIdentifierHash}-${builtins.substring 8 4 deviceIdentifierHash}-5${builtins.substring 13 3 deviceIdentifierHash}-8${builtins.substring 17 3 deviceIdentifierHash}-${builtins.substring 20 12 deviceIdentifierHash}";
  extensionPackages = import ./extensions {inherit pkgs;};
  jsonFormat = pkgs.formats.json {};

  acpConfig = jsonFormat.generate "acp.json" (import ./acp.nix);
  herdsmanConfig = jsonFormat.generate "pi-herdsman-config.json" {
    contextRetirement = false;
  };

  piSettings = jsonFormat.generate "pi-settings.json" {
    defaultModel = "gpt-6.1-sol";
    defaultProjectTrust = "ask";
    defaultProvider = "openai";
    defaultThinkingLevel = "xhigh";
    defaultTools = [
      "bash"
      "codemode"
      "edit"
      "find"
      "grep"
      "ls"
      "read"
      "write"
    ];
    deviceId = deviceIdentifier;
    enableAnalytics = false;
    enableInstallTelemetry = false;
    enabledModels = [
      "openai/gpt-6.1-sol"
      "openai/gpt-6-astra"
    ];
    lastChangelogVersion = pkgs.pi-coding-agent.version;
    packages = [
      "${extensionPackages.piHerdsman}"
    ];
    skills = [
      "${pkgs.herdr}/share/herdr/skills/herdr"
    ];
  };

  mcpConfig = jsonFormat.generate "mcp.json" (import ./mcp.nix {
    inherit inputs lib pkgs;
  });
  permissionConfig = jsonFormat.generate "pi-permission-system-config.json" (import ./permissions.nix);

  piRuntime = pkgs.writeShellApplication {
    name = "pi-runtime";
    runtimeInputs = with pkgs; [
      bash
      coreutils
      direnv
      git
      herdr
    ];
    text = ''
      export PI_OFFLINE=1

      exec ${lib.getExe pkgs.pi-coding-agent} \
        -e '${extensionPackages.piPermissionSystem}/src/index.ts' \
        "$@"
    '';
  };

  pi = pkgs.writeShellApplication {
    name = "pi";
    text = ''
      export ACP_AUTO_UPDATE=0

      if [ "''${PI_SUBAGENT_CHILD:-0}" = 1 ]; then
        exec ${lib.getExe piRuntime} "$@"
      fi

      exec ${lib.getExe piRuntime} \
        -e '${extensionPackages.billionContextPi}/dist/index.js' \
        "$@"
    '';
  };
in {
  config.hm = lib.mkIf config.features.ai.enable {
    home = {
      file = {
        ".pi/acp.json".source = acpConfig;
        ".pi/agent/AGENTS.md".source = ./AGENTS.md;
        ".pi/agent/agents" = {
          recursive = true;
          source = ./agents;
        };
        ".pi/agent/extensions/herdr-agent-state.ts".source = "${pkgs.herdr.src}/src/integration/assets/pi/herdr-agent-state.ts";
        ".pi/agent/extensions/pi-permission-system/config.json".source = permissionConfig;
        ".pi/agent/keybindings.json".source = ./keybindings.json;
        ".pi/agent/mcp.json".source = mcpConfig;
        ".pi/agent/pi-herdsman/config.json".source = herdsmanConfig;
        ".pi/agent/prompts" = {
          recursive = true;
          source = ./prompts;
        };
        ".pi/agent/settings.json".source = piSettings;
      };

      packages = [pi];
    };
  };
}
