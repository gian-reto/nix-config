{
  config,
  lib,
  ...
}: {
  config.hm = lib.mkIf config.features.opencode.enable {
    programs.opencode.settings.permission = {
      bash = {
        "alejandra *" = "allow";
        "cat *" = "allow";
        "cd *" = "allow";
        "bat *" = "allow";
        "find *" = "allow";
        "fzf *" = "allow";
        "gh help*" = "allow";
        "gh search*" = "allow";
        "gh*" = "ask";
        "git diff*" = "allow";
        "git log*" = "allow";
        "git show*" = "allow";
        "git stash list*" = "allow";
        "git status*" = "allow";
        "git*" = "ask";
        "grep *" = "allow";
        "head *" = "allow";
        "journalctl*" = "allow";
        "jq *" = "allow";
        "less *" = "allow";
        "ls*" = "allow";
        "lsd*" = "allow";
        "man *" = "allow";
        "nh os build*" = "ask";
        "nh search*" = "allow";
        "nh*" = "deny";
        "nil diagnostics*" = "allow";
        "nil parse*" = "allow";
        "nil*" = "ask";
        "nixos-rebuild*" = "deny";
        "pwd*" = "allow";
        "rg*" = "allow";
        "systemctl list-units*" = "allow";
        "systemctl list-timers*" = "allow";
        "systemctl status*" = "allow";
        "tail *" = "allow";
        "tree*" = "allow";
        "z *" = "allow";
        "*" = "ask";
      };
      edit = "allow";
      # Deny webfetch in favor of the `fetch` MCP server.
      webfetch = "deny";
    };
  };
}
