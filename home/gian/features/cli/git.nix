{
  pkgs,
  config,
  ...
}: let
  # `git commit --amend`, but for older commits. Note: Changes need to be staged
  # first. Usage: `git-fix <commit-hash>`.
  git-fix = pkgs.writeShellScriptBin "git-fix" ''
    rev="$(git rev-parse "$1")"
    git commit --fix "$@"
    GIT_SEQUENCE_EDITOR=true git rebase -i --autostash --autosquash $rev^
  '';
in {
  home.packages = [
    git-fix
  ];
  programs.git = {
    enable = true;
    package = pkgs.gitAndTools.gitFull;
    aliases = {
      graph = "log --decorate --oneline --graph";
    };
    userName = "Gian-Reto Tarnutzer";
    userEmail = "hi@giantarnutzer.com";
    extraConfig = {
      user.signing.key = "2EFB1A9CA2CE1333B22F84C8EF2E3A235297D053";
      commit.gpgSign = true;
      gpg.program = "${config.programs.gpg.package}/bin/gpg2";

      init.defaultBranch = "main";
      log.date = "iso";
      branch.sort = "committerdate";
      # Automatically track remote branch.
      push.autoSetupRemote = true;
    };
    lfs.enable = true;
  };
}