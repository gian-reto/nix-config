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
  env = import ../env.nix;
  extensionPackages = import ./extensions {inherit pkgs;};
  apparmorProfileName = "apparmor-pi-${deviceIdentifier}";
  apparmorProfile = pkgs.runCommand "pi-apparmor-profile" {} ''
    substitute ${./profile.apparmor} "$out" \
      --replace-fail '@apparmorProfiles@' '${pkgs.apparmor-profiles}' \
      --replace-fail '@profileName@' '${apparmorProfileName}'
  '';

  pi = inputs.self.wrappers.pi.wrap {
    inherit pkgs;
    # Set environment variables as weak default, such that nested processes
    # don't re-resolve 1Password references unnecessarily.
    envDefault =
      env
      // {
        ACP_AUTO_UPDATE = "0";
        PI_OFFLINE = "1";
      };
    extensions = ["${extensionPackages.piPermissionSystem}/src/index.ts"];
    # Root extensions are only loaded by the root Pi instance, not by subagents.
    rootExtensions = ["${extensionPackages.billionContextPi}/dist/index.js"];
    runShell = [
      ''
        namespaceFeatures=/sys/kernel/security/apparmor/features/namespaces/mask
        if [[ ! -r "$namespaceFeatures" ]] || [[ "$(<"$namespaceFeatures")" != *userns_create* ]]; then
          echo "The Pi filesystem policy requires AppArmor user-namespace mediation support." >&2
          exit 1
        fi
      ''
    ];
    runtimePkgs =
      map (package: {
        data = package;
        prefix = true;
      }) (with pkgs; [
        apparmor-bin-utils
        bash
        coreutils
        direnv
        fd
        git
        nodejs_24
        ripgrep
      ]);
  };
in {
  config.os = lib.mkIf config.features.ai.enable {
    security.apparmor = {
      enable = true;
      policies.${apparmorProfileName} = {
        path = apparmorProfile;
        state = "enforce";
      };
    };
  };

  config.hm = lib.mkIf config.features.ai.enable {
    home = {
      packages = [pi];

      file = let
        jsonFormat = pkgs.formats.json {};
      in {
        ".pi/acp.json".source = jsonFormat.generate "pi-acp.json" (import ./acp.nix);
        ".pi/agent/AGENTS.md".source = ./AGENTS.md;
        ".pi/agent/agents".source = ./agents;
        ".pi/agent/extensions/herdr-agent-state.ts".source = "${pkgs.herdr.src}/src/integration/assets/pi/herdr-agent-state.ts";
        ".pi/agent/extensions/pi-permission-system/config.json".source = jsonFormat.generate "pi-permissions.json" (import ./permissions.nix);
        # A stub directory prevents the permissions extension from persisting changes.
        ".pi/agent/extensions/pi-permission-system/config.json.tmp/.keep".text = "";
        ".pi/agent/keybindings.json".source = ./keybindings.json;
        ".pi/agent/mcp.json".source = jsonFormat.generate "pi-mcp.json" (import ./mcp.nix {inherit inputs lib pkgs;});
        ".pi/agent/pi-apparmor-executor/config.json".source = jsonFormat.generate "pi-apparmor-executor.json" {
          profile = apparmorProfileName;
          excludedEnvironmentVariables = builtins.attrNames env;
        };
        ".pi/agent/pi-herdsman/config.json".source = jsonFormat.generate "pi-herdsman.json" {
          contextRetirement = false;
          spawnPlacement = "subtree";
        };
        ".pi/agent/prompts" = {
          recursive = true;
          source = ./prompts;
        };
        ".pi/agent/settings.json".source = jsonFormat.generate "pi-settings.json" {
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
          skills = ["${pkgs.herdr}/share/herdr/skills/herdr"];
        };
      };
    };
  };
}
