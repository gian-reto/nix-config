{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  mcpPackages = inputs.mcp-servers-nix.packages.${pkgs.stdenv.hostPlatform.system};
  mcpNixosPackage = inputs.mcp-nixos.packages.${pkgs.stdenv.hostPlatform.system}.default;
in {
  options.features.opencode.enable = lib.mkOption {
    description = ''
      Whether to enable opencode (https://github.com/anomalyco/opencode).
    '';
    type = lib.types.bool;
    default = false;
    example = true;
  };

  config.hm = lib.mkIf config.features.opencode.enable {
    xdg.configFile = {
      "opencode/AGENTS.md" = {
        source = ./rules/AGENTS.md;
      };
      "opencode/plugins" = {
        recursive = true;
        source = ./plugins;
      };
      "opencode/prompts" = {
        recursive = true;
        source = ./prompts;
      };
    };

    programs.opencode = let
      # Base permissions.
      permission = let
        baseFilePermissions = {
          "*" = "allow";
          "*.env" = "deny";
          "*.env.*" = "deny";
          "*.env.example" = "allow";
          "*.decrypted~*" = "deny";
          "*secret*" = "deny";
        };
      in {
        read = baseFilePermissions;
        edit = baseFilePermissions;
        glob = "allow";
        grep = baseFilePermissions;
        list = "allow";
        bash = {
          "*" = "ask";

          "alejandra *" = "allow";

          "gh help *" = "allow";
          "gh search *" = "allow";

          "git diff *" = "allow";
          "git log *" = "allow";
          "git show *" = "allow";
          "git stash list *" = "allow";
          "git status *" = "allow";

          "journalctl *" = "allow";
          "ls *" = "allow";
          "lsd *" = "allow";
          "man *" = "allow";

          "nh *" = "deny";
          "nh os build *" = "ask";
          "nh search *" = "allow";

          "nil diagnostics *" = "allow";
          "nil parse *" = "allow";

          "nixos-rebuild *" = "deny";
          "pwd *" = "allow";

          "systemctl list-units *" = "allow";
          "systemctl list-timers *" = "allow";
          "systemctl status *" = "allow";

          "tree *" = "allow";
        };
        task = "allow";
        skill = "allow";
        lsp = "allow";
        todoread = "allow";
        webfetch = "allow";
        # Web search is not enabled anyways, and the Kagi MCP should be used instead.
        websearch = "deny";
        external_directory = {
          "*" = "deny";
          "$HOME/Code" = "allow";
        };
        doom_loop = "deny";
        question = "allow";

        # Context7
        "context7*" = "deny";

        # GitHub
        "github*" = "deny";

        # Kagi Search
        "kagisearch*" = "deny";

        # NixOS
        "nixos*" = "allow";

        # Time
        "time*" = "allow";
      };

      # Granular permissions for specific MCP tools.
      permissionAllowContext7Mcp = {
        "context7_query-docs" = "allow";
        "context7_resolve-library-id" = "allow";
      };
      permissionAllowGithubMcp = {
        # GitHub: Context
        "github_get_me" = "allow";
        # GitHub: Issues
        "github_issue_read" = "allow";
        "github_list_issues" = "allow";
        "github_search_issues" = "allow";
        # GitHub: Pull Requests
        "github_list_pull_requests" = "allow";
        "github_pull_request_read" = "allow";
        "github_search_pull_requests" = "allow";
        # GitHub: Repositories
        "github_get_commit" = "allow";
        "github_get_file_contents" = "allow";
        "github_get_latest_release" = "allow";
        "github_get_release_by_tag" = "allow";
        "github_get_tag" = "allow";
        "github_list_branches" = "allow";
        "github_list_commits" = "allow";
        "github_list_releases" = "allow";
        "github_list_tags" = "allow";
        "github_search_code" = "allow";
        "github_search_repositories" = "allow";
      };
      permissionAllowKagiMcp = {
        "kagisearch_kagi_extract" = "allow";
        "kagisearch_kagi_search_fetch" = "allow";
      };
    in {
      enable = true;
      package = pkgs.opencode;

      tui.theme = "system";

      settings = {
        autoshare = false;
        autoupdate = false;
        provider = {
          openai = {
            models = {
              "gpt-5.6-terra" = {
                options = {
                  reasoningEffort = "medium";
                  textVerbosity = "medium";
                  reasoningSummary = "auto";
                  include = ["reasoning.encrypted_content"];
                };
              };
              "gpt-5.6-sol" = {
                options = {
                  reasoningEffort = "high";
                  textVerbosity = "medium";
                  reasoningSummary = "auto";
                  include = ["reasoning.encrypted_content"];
                };
              };
            };
          };
          # openrouter.models = {
          #   "deepseek/deepseek-v4-flash" = {
          #     name = "DeepSeek V4 Flash";
          #     options = {
          #       provider = {
          #         only = ["novita" "parasail"];
          #       };
          #       reasoning = {
          #         enabled = true;
          #       };
          #       reasoningEffort = "xhigh";
          #     };
          #   };
          #   "z-ai/glm-5.1" = {
          #     name = "GLM-5.1";
          #     options = {
          #       provider = {
          #         only = ["friendli" "fireworks" "novita" "parasail"];
          #       };
          #     };
          #   };
          # };
        };
        small_model = "openai/gpt-5.6-terra";

        # Global permissions.
        permission = permission;

        agent = {
          build = {
            description = "Builds new features or entire applications based on a high-level description of what needs to be done.";
            mode = "primary";
            model = "openai/gpt-5.6-terra";
            prompt = "{file:prompts/build.md}";
            permission = permissionAllowContext7Mcp;
            temperature = 0.35;

            # Additional model options.
            reasoningEffort = "high";
            textVerbosity = "medium";
          };
          "build-expert" = {
            description = "Builds complex new features or entire applications based on a high-level description of what needs to be done.";
            mode = "primary";
            model = "openai/gpt-5.6-sol";
            prompt = "{file:prompts/build.md}";
            permission = permissionAllowContext7Mcp;
            temperature = 0.45;

            # Additional model options.
            reasoningEffort = "max";
            textVerbosity = "medium";
          };
          compaction = {
            model = "openai/gpt-5.6-terra";
            temperature = 0.05;
          };
          explore = {
            description = "Finds relevant locations in the codebase to start working on a given task, based on a description of the task and the project context.";
            mode = "subagent";
            model = "openai/gpt-5.6-terra";
            prompt = "{file:prompts/explore.md}";
            permission = {
              bash = "deny";
              edit = "deny";
              task = "deny";
              webfetch = "deny";
              external_directory = "deny";
            };
            steps = 70;
            temperature = 0.3;

            # Additional model options.
            reasoningEffort = "medium";
            textVerbosity = "medium";
          };
          general = {
            # Disable built-in `general` agent.
            disable = true;
          };
          "github-research" = {
            description = "Finds relevant code examples on GitHub based on the given task description, technologies, and other constraints.";
            mode = "subagent";
            model = "openai/gpt-5.6-terra";
            prompt = "{file:prompts/github-research.md}";
            permission =
              permissionAllowContext7Mcp
              // permissionAllowGithubMcp
              // {
                bash = "deny";
                edit = "deny";
                task = "deny";
                external_directory = "deny";
              };
            steps = 70;
            temperature = 0.25;

            # Additional model options.
            reasoningEffort = "medium";
            textVerbosity = "medium";
          };
          plan = {
            # Disable built-in `plan` agent.
            disable = true;
          };
          "web-research" = {
            description = "Conducts web-based research to gather information on a specific topic using a search engine and summarises the findings.";
            mode = "subagent";
            model = "openai/gpt-5.6-terra";
            prompt = "{file:prompts/web-research.md}";
            permission =
              permissionAllowContext7Mcp
              // permissionAllowKagiMcp
              // {
                bash = "deny";
                edit = "deny";
                task = "deny";
                external_directory = "deny";
              };
            steps = 70;
            temperature = 0.25;

            # Additional model options.
            reasoningEffort = "medium";
            textVerbosity = "medium";
          };
          summary = {
            hidden = true;
            model = "openai/gpt-5.6-terra";
            temperature = 0.05;
          };
          title = {
            hidden = true;
            model = "openai/gpt-5.6-terra";
            temperature = 0.05;

            # Additional model options.
            reasoningEffort = "none";
            textVerbosity = "low";
          };
        };

        mcp = {
          context7 = {
            type = "local";
            enabled = true;
            command = ["${mcpPackages.context7-mcp}/bin/context7-mcp"];
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
              "--log-driver=none"
              "-i"
              "--rm"
              "-e"
              "GITHUB_PERSONAL_ACCESS_TOKEN"
              "-e"
              "GITHUB_READ_ONLY"
              "-e"
              "GITHUB_TOOLS"
              "-e"
              "GITHUB_TOOLSETS"
              "ghcr.io/github/github-mcp-server:v0.33.0@sha256:a9dd39eec67f09ded51631c79641dd72acb4945c6391df47824fa2d508b5431b"
            ];
            environment = {
              "GITHUB_PERSONAL_ACCESS_TOKEN" = "op://Personal/mttiacgfb5emvfmgxia6b4hvza/personal-access-token-mcp";
              "GITHUB_READ_ONLY" = "1";
              "GITHUB_TOOLS" = lib.concatStringsSep "," [
                "get_me"
                "issue_read"
                "list_issues"
                "search_issues"
                "list_pull_requests"
                "pull_request_read"
                "search_pull_requests"
                "get_commit"
                "get_file_contents"
                "get_latest_release"
                "get_release_by_tag"
                "get_tag"
                "list_branches"
                "list_commits"
                "list_releases"
                "list_tags"
                "search_code"
                "search_repositories"
              ];
              "GITHUB_TOOLSETS" = "context,issues,pull_requests,repos";
            };
          };
          kagisearch = {
            type = "local";
            enabled = true;
            timeout = 60000;
            command = [
              "op"
              "run"
              "--"
              "podman"
              "run"
              "--log-driver=none"
              "-i"
              "--rm"
              "-e"
              "KAGI_API_KEY"
              "-e"
              "FASTMCP_LOG_LEVEL=ERROR"
              "-e"
              "UV_PYTHON_DOWNLOADS=never"
              "--mount"
              "type=volume,src=opencode-mcp-kagisearch-uv-cache,dst=/root/.cache/uv"
              "ghcr.io/astral-sh/uv:python3.12-trixie-slim"
              "uvx"
              "--python"
              "3.12"
              "--from"
              "kagimcp==1.0.0"
              "kagimcp"
            ];
            environment = {
              "KAGI_API_KEY" = "op://Personal/s47avhmxjyaqgpvexzolwcirba/api-key-v1-opencode";
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
