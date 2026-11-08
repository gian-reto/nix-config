{
  commandEffects.jq.effects = "read";
  promptTimeoutMs = 2 * 60 * 1000;

  permission = {
    "*" = "ask";

    bash = {
      "*" = "ask";

      "[ *" = "allow";
      "alejandra *" = "allow";
      "basename *" = "allow";
      "cat *" = "allow";
      "cd *" = "allow";
      "cmp *" = "allow";
      "col *" = "allow";
      "comm *" = "allow";
      "command -v *" = "allow";
      "cut *" = "allow";
      "df *" = "allow";
      "dirname *" = "allow";
      "du *" = "allow";
      "echo *" = "allow";

      # These exceptions sort after the broad allow in the generated JSON.
      "find *" = "allow";
      "find *-delete*" = "ask";
      "find *-exec*" = "ask";
      "find *-fls*" = "ask";
      "find *-fprint*" = "ask";
      "find *-ok*" = "ask";
      "free *" = "allow";

      "gh help *" = "allow";
      "gh search *" = "allow";

      # Fixed prefixes need their own execution and file-output exceptions.
      "git --no-pager diff *" = "allow";
      "git --no-pager diff *--ext*" = "ask";
      "git --no-pager diff *--ou*" = "ask";
      "git --no-pager diff *--textc*" = "ask";
      "git --no-pager log *" = "allow";
      "git --no-pager log *--ext*" = "ask";
      "git --no-pager log *--ou*" = "ask";
      "git --no-pager log *--textc*" = "ask";
      "git --no-pager show *" = "allow";
      "git --no-pager show *--ext*" = "ask";
      "git --no-pager show *--ou*" = "ask";
      "git --no-pager show *--textc*" = "ask";
      "git check-ignore *" = "allow";
      "git diff *" = "allow";
      "git diff *--ext*" = "ask";
      "git diff *--ou*" = "ask";
      "git diff *--textc*" = "ask";
      "git log *" = "allow";
      "git log *--ext*" = "ask";
      "git log *--ou*" = "ask";
      "git log *--textc*" = "ask";
      "git ls-files *" = "allow";
      "git ls-tree *" = "allow";
      "git rev-parse *" = "allow";
      "git show *" = "allow";
      "git show *--ext*" = "ask";
      "git show *--ou*" = "ask";
      "git show *--textc*" = "ask";
      "git stash list *" = "allow";
      "git status *" = "allow";

      "head *" = "allow";
      "id *" = "allow";
      "journalctl *" = "allow";
      "jq *" = "allow";
      "ls *" = "allow";
      "lsd *" = "allow";
      "man *" = "allow";

      "nh *" = "deny";
      "nh os build *" = "ask";
      "nh search *" = "allow";

      "nil diagnostics *" = "allow";
      "nil parse *" = "allow";

      "nixos-rebuild *" = "deny";
      "paste *" = "allow";
      "printf *" = "allow";
      "ps *" = "allow";
      "pwd *" = "allow";
      "readlink *" = "allow";
      "realpath *" = "allow";
      "rg *" = "allow";
      "rg *--hostname-bin*" = "ask";
      "rg *--pre*" = "ask";
      "sha256sum *" = "allow";
      "stat *" = "allow";

      "tail *" = "allow";
      "test *" = "allow";
      "tr *" = "allow";
      "tree *" = "allow";
      "uname *" = "allow";
      "wc *" = "allow";
      "which *" = "allow";
      "whoami *" = "allow";
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
      "~/.pi/agent/sessions" = "allow";
      "~/.pi/agent/sessions/**" = "allow";
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
