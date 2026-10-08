{
  permission = {
    "*" = "allow";

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

    external_directory = "ask";

    path = {
      "*" = "allow";
      "*.decrypted~*" = "deny";
      "*.env" = "deny";
      "*.env.*" = "deny";
      "*.env.example" = "allow";
      "*secret*" = "deny";
    };
  };
}
