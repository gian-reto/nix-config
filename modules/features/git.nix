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

    programs.delta = {
      enable = true;

      enableGitIntegration = true;
    };

    programs.git = {
      enable = true;

      package = pkgs.gitAndTools.gitFull;
      lfs.enable = true;

      settings = {
        alias = {
          graph = "log --decorate --oneline --graph";
        };
        branch.sort = "committerdate";
        commit.gpgSign = true;
        core = {
          editor = "code-insiders --wait --new-window";
        };
        gpg.program = "${hmConfig.programs.gpg.package}/bin/gpg2";
        init.defaultBranch = "main";
        log.date = "iso";
        # Automatically track remote branch.
        push.autoSetupRemote = true;
        user = {
          email = "hi@giantarnutzer.com";
          name = "Gian-Reto Tarnutzer";
          signingKey = "2EFB1A9CA2CE1333B22F84C8EF2E3A235297D053";
        };
      };
    };

    programs.gh = {
      enable = true;

      package = pkgs.gh;
      settings = {
        color_labels = "enabled";
        editor = "code-insiders --wait --new-window";
        git_protocol = "ssh";
        pager = lib.mkIf config.features.bat.enable "bat";
      };
      gitCredentialHelper = {
        enable = true;
      };
    };

    programs.lazygit = {
      enable = true;

      settings = {
        disableStartupPopups = true;
        git = {
          autoFetch = false;
          autoRefresh = false;
          allBranchesLogCmds = [
            "git log --graph --all --abbrev-commit --color=always --decorate  --pretty=full --show-signature"
          ];
          branchLogCmd = "git log --graph --abbrev-commit --color=always --decorate --pretty=full --show-signature {{branchName}} --";
          commit = {
            signOff = true;
          };
          paging = {
            colorArg = "always";
            pager = "delta --dark --paging=never --line-numbers --hyperlinks --hyperlinks-file-link-format=\"lazygit-edit://{path}:{line}\"";
            useConfig = false;
          };
        };
        gui = {
          filterMode = "fuzzy";
          nerdFontsVersion = "3";
        };
        os = {
          # Full edit preset settings (in place of `editPreset = "vscode"`).
          # Based on:
          # https://github.com/jesseduffield/lazygit/blob/61636d820c9bb6f0f52b0821b7114e9c7ba38e0b/pkg/config/editor_presets.go#L94
          # but adapted to `code-insiders`.
          edit = "code-insiders --reuse-window -- {{filename}}";
          editAtLine = "code-insiders --reuse-window --goto -- {{filename}}:{{line}}";
          editAtLineAndWait = "code-insiders --reuse-window --goto --wait -- {{filename}}:{{line}}";
          editInTerminal = false;
          openDirInEditor = "code-insiders -- {{dir}}";

          # Other settings.
          open = "xdg-open {{filename}}";
          openLink = "xdg-open {{link}}";
        };
        update = {
          method = "never";
        };
      };
    };
  };
}
