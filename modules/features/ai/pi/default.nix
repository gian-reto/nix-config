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
  profileName = "apparmor-pi-${deviceIdentifier}";
  apparmorProfile = pkgs.runCommand "pi-apparmor-profile" {} ''
    substitute ${./profile.apparmor} "$out" \
      --replace-fail '@apparmorProfiles@' '${pkgs.apparmor-profiles}' \
      --replace-fail '@profileName@' '${profileName}'
  '';

  acpConfig = jsonFormat.generate "acp.json" (import ./acp.nix);
  apparmorExecutorConfig = jsonFormat.generate "pi-apparmor-executor-config.json" {
    profile = profileName;
  };
  herdsmanConfig = jsonFormat.generate "pi-herdsman-config.json" {
    contextRetirement = false;
    spawnPlacement = "subtree";
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
      "${extensionPackages.piApparmorExecutor}"
      "${extensionPackages.piHerdrPermissions}"
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
      apparmor-bin-utils
      bash
      coreutils
      direnv
      fd
      git
      herdr
      nodejs_24
      ripgrep
    ];
    text = ''
      namespaceFeatures=/sys/kernel/security/apparmor/features/namespaces/mask
      if [[ ! -r "$namespaceFeatures" ]] || [[ "$(<"$namespaceFeatures")" != *userns_create* ]]; then
        echo "The Pi filesystem policy requires AppArmor user-namespace mediation support." >&2
        exit 1
      fi

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
  config.os = lib.mkIf config.features.ai.enable {
    security.apparmor = {
      enable = true;
      policies.${profileName} = {
        path = apparmorProfile;
        state = "enforce";
      };
    };
  };

  config.hm = lib.mkIf config.features.ai.enable {
    home = {
      file = {
        ".pi/acp.json".source = acpConfig;
        ".pi/agent/AGENTS.md".source = ./AGENTS.md;
        ".pi/agent/agents" = {
          source = ./agents;
        };
        ".pi/agent/extensions/herdr-agent-state.ts".source = "${pkgs.herdr.src}/src/integration/assets/pi/herdr-agent-state.ts";
        ".pi/agent/extensions/pi-permission-system/config.json".source = permissionConfig;
        # Hack: A stub directory prevents the permissions extension from saving
        # config changes to disk.
        ".pi/agent/extensions/pi-permission-system/config.json.tmp/.keep".text = "";
        ".pi/agent/keybindings.json".source = ./keybindings.json;
        ".pi/agent/mcp.json".source = mcpConfig;
        ".pi/agent/pi-apparmor-executor/config.json".source = apparmorExecutorConfig;
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
