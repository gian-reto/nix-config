{
  config,
  lib,
  pkgs,
  inputs,
  hmConfig,
  ...
}: let
  mcpPackages = inputs.mcp-servers-nix.packages.${pkgs.system};
  mcpNixosPackage = inputs.mcp-nixos.packages.${pkgs.system}.default;

  # Create prompt files in the nix store.
  buildPrompt = pkgs.writeText "build-prompt.md" (builtins.readFile ./prompts/build.md);
  codeExampleResearchPrompt = pkgs.writeText "code-example-research-prompt.md" (builtins.readFile ./prompts/code-example-research.md);
  debugPrompt = pkgs.writeText "debug-prompt.md" (builtins.readFile ./prompts/debug.md);
  planPrompt = pkgs.writeText "plan-prompt.md" (builtins.readFile ./prompts/plan.md);
in {
  options.features.opencode.enable = lib.mkOption {
    description = ''
      Whether to enable opencode (https://github.com/sst/opencode).
    '';
    type = lib.types.bool;
    default = false;
    example = true;
  };

  config.hm = lib.mkIf config.features.opencode.enable {
    home.file.".config/opencode/AGENTS.md".text = ''
      # Global Coding Guidelines

      These are global guidelines that you MUST always adhere to.

      - You MUST ALWAYS adhere to the current project's AGENTS.md file if it exists.
      - You MUST ALWAYS ask before running consequential commands (e.g., commands that apply changes to the system).
      - You MUST ALWAYS perform a deeper research to find existing patterns or integrations in the existing code.
      - You MUST ALWAYS mimic the existing code style and structure.
      - You MUST ALWAYS prefer a clean functional coding approach.
      - You MUST ALWAYS consider if there is a better approach to a solution compared to the one being asked by the user. Feel free to challenge the user and make suggestions.
      - You MUST ONLY add comments if the code you are creating is complex, or if it has non-obvious implications (e.g., for workarounds).
    '';

    programs.opencode = {
      enable = true;
      package = pkgs.opencode;

      settings = {
        autoshare = false;
        autoupdate = false;
        model = "github-copilot/claude-sonnet-4";
        small_model = "github-copilot/gpt-5-mini";
        theme = "system";
        permission = {
          edit = "allow";
          # Deny webfetch in favor of the `fetch` MCP server.
          webfetch = "deny";
          bash = {
            "alejandra" = "allow";
            "cat" = "allow";
            "cd" = "allow";
            "bat" = "allow";
            "find" = "allow";
            "fzf" = "allow";
            "gh help" = "allow";
            "gh search *" = "allow";
            "gh *" = "ask";
            "git diff" = "allow";
            "git log" = "allow";
            "git show" = "allow";
            "git stash list" = "allow";
            "git status" = "allow";
            "git *" = "ask";
            "grep" = "allow";
            "head" = "allow";
            "journalctl" = "allow";
            "jq" = "allow";
            "less" = "allow";
            "ls" = "allow";
            "lsd" = "allow";
            "man" = "allow";
            "nh os build" = "ask";
            "nh search *" = "allow";
            "nh *" = "deny";
            "nil diagnostics" = "allow";
            "nil parse" = "allow";
            "nil *" = "ask";
            "nixos-rebuild" = "deny";
            "pwd" = "allow";
            "rg *" = "allow";
            "tail" = "allow";
            "tree" = "allow";
            "z *" = "allow";
            "*" = "ask";
          };
        };

        agent = {
          build = {
            description = "Builds new features or entire applications based on a high-level description of what needs to be done.";
            mode = "primary";
            model = "github-copilot/claude-sonnet-4";
            prompt = "{file:${buildPrompt}}";
            tools = {
              bash = true;
              edit = true;
              patch = true;
              write = true;
              webfetch = false;
            };
          };
          "code-example-research" = {
            description = "Finds relevant code examples from GitHub based on provided keywords and a brief description of what you're looking for.";
            mode = "subagent";
            model = "github-copilot/gpt-5-mini";
            prompt = "{file:${codeExampleResearchPrompt}}";
            tools = {
              bash = true;
              edit = false;
              patch = false;
              write = false;
              webfetch = false;
            };
          };
          debug = {
            description = "Finds and fixes bugs in the codebase based on error messages, logs, or a description of the issue.";
            mode = "primary";
            model = "github-copilot/claude-sonnet-4";
            prompt = "{file:${debugPrompt}}";
            tools = {
              bash = true;
              edit = true;
              patch = true;
              write = true;
              webfetch = false;
            };
          };
          plan = {
            description = "Creates a clear and actionable plan for implementing a feature or solving a problem based on a high-level description of the task.";
            mode = "primary";
            model = "github-copilot/gpt-5";
            prompt = "{file:${planPrompt}}";
            tools = {
              bash = true;
              edit = false;
              patch = false;
              write = false;
              webfetch = false;
            };
          };
        };

        mcp = {
          context7 = {
            type = "local";
            enabled = true;
            command = ["${mcpPackages.context7-mcp}/bin/context7-mcp"];
          };
          fetch = {
            type = "local";
            enabled = true;
            command = ["podman" "run" "-i" "--rm" "mcp/fetch"];
          };
          filesystem = {
            type = "local";
            enabled = true;
            command = [
              "${mcpPackages.mcp-server-filesystem}/bin/mcp-server-filesystem"
              "${hmConfig.home.homeDirectory}/Code"
              "${hmConfig.home.homeDirectory}/.config"
            ];
          };
          git = {
            type = "local";
            enabled = true;
            command = ["${mcpPackages.mcp-server-git}/bin/mcp-server-git"];
          };
          memory = {
            type = "local";
            enabled = true;
            command = ["${mcpPackages.mcp-server-memory}/bin/mcp-server-memory"];
          };
          nixos = {
            type = "local";
            enabled = true;
            command = ["${mcpNixosPackage}/bin/mcp-nixos"];
          };
          playwright = {
            type = "local";
            enabled = true;
            command = [
              "${mcpPackages.playwright-mcp}/bin/mcp-server-playwright"
              "--executable-path"
              "${pkgs.chromium}/bin/chromium"
            ];
          };
          "sequential-thinking" = {
            type = "local";
            enabled = true;
            command = ["${mcpPackages.mcp-server-sequential-thinking}/bin/mcp-server-sequential-thinking"];
          };
          time = {
            type = "local";
            enabled = true;
            command = ["${mcpPackages.mcp-server-time}/bin/mcp-server-time"];
          };
        };
      };
    };
  };
}
