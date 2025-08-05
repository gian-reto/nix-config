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
  codePrompt = pkgs.writeText "code-prompt.md" (builtins.readFile ./prompts/code.md);
  debugPrompt = pkgs.writeText "debug-prompt.md" (builtins.readFile ./prompts/debug.md);
  documentPrompt = pkgs.writeText "document-prompt.md" (builtins.readFile ./prompts/document.md);
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
        small_model = "github-copilot/gpt-4.1";
        theme = "system";

        mode = {
          code = {
            model = "github-copilot/claude-sonnet-4";
            prompt = "{file:${codePrompt}}";
          };
          debug = {
            model = "github-copilot/claude-sonnet-4";
            prompt = "{file:${debugPrompt}}";
            tools = {
              bash = true;
              edit = false;
              glob = true;
              grep = true;
              list = true;
              patch = false;
              read = true;
              todowrite = false;
              todoread = true;
              webfetch = true;
              write = false;
            };
          };
          document = {
            model = "github-copilot/gpt-4.1";
            prompt = "{file:${documentPrompt}}";
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
