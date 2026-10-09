{
  permission = {
    "*" = "ask";

    acp_cache = "allow";
    acp_status = "allow";
    agent_close = "allow";
    agent_continue = "allow";
    agent_delegate = "allow";
    agent_inspect = "allow";
    agent_interrupt = "allow";
    agent_list = "allow";
    agent_reply = "allow";
    agent_steer = "allow";
    agent_transcript = "allow";
    ask_owner = "allow";

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

      "systemctl list-timers *" = "allow";
      "systemctl list-units *" = "allow";
      "systemctl status *" = "allow";

      "tree *" = "allow";
    };

    codemode = "allow";
    compress = "allow";
    decompress = "allow";
    edit = "allow";
    external_directory = "ask";
    find = "allow";
    grep = "allow";
    ls = "allow";

    mcp = {
      "*" = "ask";
      "firecrawl:firecrawl_developer_search" = "allow";
      "kagisearch:kagi_extract" = "allow";
      "kagisearch:kagi_search_fetch" = "allow";
      "nixos:nix" = "allow";
      "nixos:nix_versions" = "allow";
      "time:convert_time" = "allow";
      "time:get_current_time" = "allow";
    };

    path = {
      "*" = "allow";
      "*.decrypted~*" = "deny";
      "*.env" = "deny";
      "*.env.*" = "deny";
      "*.env.example" = "allow";
      "*secret*" = "deny";
    };

    read = "allow";
    search_context = "allow";
    skill = "allow";
    write = "allow";
  };
}
