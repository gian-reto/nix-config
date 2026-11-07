{
  inputs,
  lib,
  pkgs,
}: let
  env = import ../env.nix;
  # Empty environment with all variables from env set to empty strings to mask
  # them from the MCP servers that don't need them.
  emptyEnv = lib.genAttrs (builtins.attrNames env) (_: "");
  mcpNixos = inputs.mcp-nixos.packages.${pkgs.stdenv.hostPlatform.system}.default;
in {
  mcpServers = {
    firecrawl = {
      command = lib.getExe pkgs.firecrawl-mcp;
      description = "Search developer documentation, source repositories, issues, and pull requests";
      env =
        emptyEnv
        // {
          FIRECRAWL_API_KEY = "\${FIRECRAWL_API_KEY}";
          FIRECRAWL_NO_ENDPOINT_FEEDBACK = "1";
          FIRECRAWL_NO_SEARCH_FEEDBACK = "1";
        };
      exposure = "hidden";
      timeout = 120;
      toolExposure.firecrawl_developer_search = "codemode";
    };

    kagisearch = {
      args = [
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
        "type=volume,src=pi-mcp-kagisearch-uv-cache,dst=/root/.cache/uv"
        "ghcr.io/astral-sh/uv:python3.12-trixie-slim@sha256:19a765e8ca941a161f9913588beb7aa6cf20794dd69aebf177d985b0b75a3a76"
        "uvx"
        "--python"
        "3.12"
        "--from"
        "kagimcp==1.0.0"
        "kagimcp"
      ];
      command = lib.getExe pkgs.podman;
      description = "Search the web and extract page content";
      env =
        emptyEnv
        // {
          KAGI_API_KEY = "\${KAGI_API_KEY}";
        };
      exposure = "hidden";
      timeout = 60;
      toolExposure = {
        kagi_extract = "codemode";
        kagi_search_fetch = "codemode";
      };
    };

    nixos = {
      command = "${mcpNixos}/bin/mcp-nixos";
      description = "Query current Nix packages, options, flakes, documentation, and version history";
      env = emptyEnv;
      exposure = "hidden";
      timeout = 60;
      toolExposure = {
        nix = "codemode";
        nix_versions = "codemode";
      };
    };

    time = {
      command = lib.getExe pkgs.mcp-server-time;
      description = "Get current times and convert between time zones";
      env = emptyEnv;
      exposure = "hidden";
      timeout = 30;
      toolExposure = {
        convert_time = "codemode";
        get_current_time = "codemode";
      };
    };
  };
}
