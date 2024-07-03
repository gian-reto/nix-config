{
  config,
  lib,
  pkgs,
  hmConfig,
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
  options.features.git.enable = lib.mkOption {
    description = ''
      Whether to enable `git`.
    '';
    type = lib.types.bool;
    default = false;
    example = true;
  };

  config.hm = lib.mkIf config.features.git.enable {
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
        branch.sort = "committerdate";
        commit.gpgSign = true;
        core = {
          editor = "code --wait --new-window";
        };
        gpg.program = "${hmConfig.programs.gpg.package}/bin/gpg2";
        init.defaultBranch = "main";
        log.date = "iso";
        # Automatically track remote branch.
        push.autoSetupRemote = true;
        user.signing.key = "2EFB1A9CA2CE1333B22F84C8EF2E3A235297D053";
      };

      lfs.enable = true;
    };
  };
}