{
  config,
  hmConfig,
  inputs,
  lib,
  pkgs,
  ...
}: let
  mcpPackages = inputs.mcp-servers-nix.packages.${pkgs.system};
  mcpNixosPackage = inputs.mcp-nixos.packages.${pkgs.system}.default;

  # Create prompt files in the nix store.
  buildPrompt = pkgs.writeText "build-prompt.md" (builtins.readFile ./prompts/build.md);
  debugPrompt = pkgs.writeText "debug-prompt.md" (builtins.readFile ./prompts/debug.md);
  planPrompt = pkgs.writeText "plan-prompt.md" (builtins.readFile ./prompts/plan.md);
in {
  imports = [
    ./permission.nix
  ];

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

      These are global guidelines that you MUST always adhere to:

      - You MUST ALWAYS adhere to the current project's AGENTS.md file if it exists.
      - You MUST ALWAYS ask before running consequential commands (e.g., commands that apply changes to the system).
      - You MUST ALWAYS perform a deeper research to find existing patterns or integrations in the existing code.
      - You MUST ALWAYS mimic the existing code style and structure.
      - You MUST ALWAYS prefer a clean functional coding approach.
      - You MUST ALWAYS consider if there is a better approach to a solution compared to the one being asked by the user. Feel free to challenge the user and make suggestions.
      - You MUST ONLY add comments if the code you are creating is complex, or if it has non-obvious implications (e.g., for workarounds).

      ## Helpful information

      - You have many tools and MCP servers at your disposal. Try to use them to their full extent. These include:
        - `context7` MCP server / tool to look up documentation and verify syntax and features.
        - `fetch` MCP server / tool to retrieve information from the internet.
        - `git` MCP server / tool to interact with git and search the git history.
        - `memory` MCP server / tool to store and retrieve relevant information while working on a task.
        - `nixos` MCP server / tool to look up NixOS-related information, as well as packages and options.
        - `playwright` MCP server / tool to interact with web pages in a headless browser.
        - `sequential-thinking` MCP server / tool to perform complex reasoning tasks step-by-step.
        - `time` MCP server / tool to get the current date and time.
      - You have access to the command line. Prefer allowed commands, such as `bat`, `cat`, `find`, `fzf`, `gh`, `git`, `grep`, `head`, `journalctl`, `jq`, `less`, `ls`, `lsd`, `man`, `nh`, `nil`, `pwd`, `rg`, `tail`, `tree`, and `z`.
    '';

    # Create some directories and files needed by the opencode config below.
    systemd.user.tmpfiles.rules = [
      "d /home/gian/.cache/opencode/memory 0755 ${hmConfig.home.username} users - -"
      "f /home/gian/.cache/opencode/memory/memory.json 0644 ${hmConfig.home.username} users - -"
    ];

    programs.opencode = {
      enable = true;
      package = pkgs.opencode;

      settings = {
        autoshare = false;
        autoupdate = false;
        model = "github-copilot/gpt-5";
        small_model = "github-copilot/gpt-5-mini";
        theme = "system";

        agent = let
          # Enable or disable various tools provided by MCP servers. Keep mostly read-only.
          mcpTools = {
            # Context7
            "context7*" = false;
            "context7_get_library_docs" = true;
            "context7_resolve_library_id" = true;

            # Fetch
            "fetch*" = false;
            "fetch_fetch" = true;

            # Git
            "git*" = false;
            "git_git_branch" = true;
            "git_git_diff*" = true;
            "git_git_log" = true;
            "git_git_show" = true;
            "git_git_status" = true;

            # GitHub
            "github*" = false;
            # GitHub: Context
            "github_get_me" = true;
            # GitHub: Discussions
            "github_get_discussion" = true;
            "github_get_discussion_comments" = true;
            "github_list_discussion_categories" = true;
            "github_list_discussions" = true;
            # GitHub: Issues
            "github_get_issue" = true;
            "github_get_issue_comments" = true;
            "github_list_issues" = true;
            "github_list_sub_issues" = true;
            "github_search_issues" = true;
            # GitHub: Pull Requests
            "github_get_pull_request" = true;
            "github_get_pull_request_diff" = true;
            "github_get_pull_request_files" = true;
            "github_get_pull_request_review_comments" = true;
            "github_get_pull_request_reviews" = true;
            "github_get_pull_request_status" = true;
            "github_list_pull_requests" = true;
            "github_request_copilot_review" = true;
            "github_search_pull_requests" = true;
            # GitHub: Repositories
            "github_get_commit" = true;
            "github_get_file_contents" = true;
            "github_get_latest_release" = true;
            "github_get_release_by_tag" = true;
            "github_get_tag" = true;
            "github_list_branches" = true;
            "github_list_commits" = true;
            "github_list_releases" = true;
            "github_list_starred_repositories" = true;
            "github_list_tags" = true;
            "github_search_code" = true;
            "github_search_repositories" = true;
            # GitHub: Security Advisories
            "github_get_global_security_advisory" = true;
            "github_list_global_security_advisories" = true;
            "github_list_org_repository_security_advisories" = true;
            "github_list_repository_security_advisories" = true;
            # GitHub: Users
            "github_search_users" = true;

            # Kagi Search
            "kagisearch*" = false;
            "kagisearch_kagi_search_fetch" = true;
            "kagisearch_kagi_summarizer" = true;

            # Memory
            "memory*" = true;

            # NixOS
            "nixos*" = true;

            # Sequential Thinking
            "sequential-thinking*" = true;

            # Time
            "time*" = true;
          };
        in {
          build = {
            description = "Builds new features or entire applications based on a high-level description of what needs to be done.";
            mode = "primary";
            model = "github-copilot/gpt-5";
            prompt = "{file:${buildPrompt}}";
            tools =
              {
                bash = true;
                edit = true;
                glob = true;
                grep = true;
                list = true;
                patch = true;
                read = true;
                todoread = true;
                todowrite = true;
                # Disabled in favor of the `fetch` MCP server.
                webfetch = false;
                write = true;
              }
              // mcpTools;
          };
          debug = {
            description = "Finds and fixes bugs in the codebase based on error messages, logs, or a description of the issue.";
            mode = "primary";
            model = "github-copilot/gpt-5";
            prompt = "{file:${debugPrompt}}";
            tools =
              {
                bash = true;
                edit = true;
                glob = true;
                grep = true;
                list = true;
                patch = false;
                read = true;
                todoread = true;
                todowrite = true;
                # Disabled in favor of the `fetch` MCP server.
                webfetch = false;
                write = true;
              }
              // mcpTools;
          };
          plan = {
            description = "Creates a clear and actionable plan for implementing a feature or solving a problem based on a high-level description of the task.";
            mode = "subagent";
            model = "github-copilot/gpt-5";
            prompt = "{file:${planPrompt}}";
            tools =
              {
                bash = true;
                edit = false;
                glob = true;
                grep = true;
                list = true;
                patch = false;
                read = true;
                todoread = true;
                todowrite = true;
                # Disabled in favor of the `fetch` MCP server.
                webfetch = false;
                write = false;
              }
              // mcpTools;
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
          git = {
            type = "local";
            enabled = true;
            command = ["${mcpPackages.mcp-server-git}/bin/mcp-server-git"];
          };
          github = {
            type = "local";
            enabled = true;
            command = [
              "op"
              "run"
              "--"
              "podman"
              "run"
              "-i"
              "--rm"
              "-e"
              "GITHUB_PERSONAL_ACCESS_TOKEN"
              "-e"
              "GITHUB_READ_ONLY"
              "-e"
              "GITHUB_TOOLSETS"
              "ghcr.io/github/github-mcp-server"
            ];
            environment = {
              "GITHUB_PERSONAL_ACCESS_TOKEN" = "op://Personal/mttiacgfb5emvfmgxia6b4hvza/personal-access-token-mcp";
              "GITHUB_READ_ONLY" = "1";
              "GITHUB_TOOLSETS" = "context,discussions,issues,pull_requests,repos,security_advisories,users";
            };
          };
          kagisearch = {
            type = "local";
            enabled = true;
            command = [
              "op"
              "run"
              "--"
              "podman"
              "run"
              "-i"
              "--rm"
              "-e"
              "KAGI_API_KEY"
              "mcp/kagisearch"
            ];
            environment = {
              "KAGI_API_KEY" = "op://Personal/s47avhmxjyaqgpvexzolwcirba/api-token";
            };
          };
          memory = {
            type = "local";
            enabled = true;
            command = ["${mcpPackages.mcp-server-memory}/bin/mcp-server-memory"];
            environment = {
              "MEMORY_FILE_PATH" = "/home/gian/.cache/opencode/memory/memory.json";
            };
          };
          nixos = {
            type = "local";
            enabled = true;
            command = ["${mcpNixosPackage}/bin/mcp-nixos"];
          };
          # Works, but is overkill at the moment.
          #
          # playwright = {
          #   type = "local";
          #   enabled = true;
          #   command = [
          #     "${mcpPackages.playwright-mcp}/bin/mcp-server-playwright"
          #     "--executable-path"
          #     "${pkgs.chromium}/bin/chromium"
          #   ];
          # };
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
