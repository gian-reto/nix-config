{
  permission = {
    "*" = "ask";

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
    edit = "allow";
    external_directory = "ask";
    external_directory_read = {
      "*" = "ask";
      "/nix/store" = "allow";
      "/nix/store/**" = "allow";
      "~/.cache/pi/acp-decompress" = "allow";
      "~/.cache/pi/acp-decompress/**" = "allow";
    };
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
    skill = "allow";
    write = "allow";

    # Tools of `billion-context-pi`.
    acp_cache = "allow";
    acp_status = "allow";
    compress = "allow";
    decompress = "allow";
    search_context = "allow";

    # Tools of `pi-herdsman`.
    ask_owner = "allow";
    close_agent = "allow";
    continue_agent = "allow";
    delegate_agent = "allow";
    delegate_project = "allow";
    inspect_agent = "allow";
    inspect_staff = "allow";
    interrupt_agent = "allow";
    list_agents = "allow";
    list_peers = "allow";
    list_staff = "allow";
    message_peer = "allow";
    message_staff = "allow";
    message_supervisor = "allow";
    read_agent_transcript = "allow";
    read_staff_transcript = "allow";
    reply_agent = "allow";
    resume_project = "allow";
    steer_agent = "allow";
    stop_lead = "allow";
  };
}
