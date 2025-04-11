{
  config,
  lib,
  ...
}: {
  options.features.zsh.enable = lib.mkOption {
    description = ''
      Whether to enable ZSH.
    '';
    type = lib.types.bool;
    default = false;
    example = true;
  };

  config.os = lib.mkIf config.features.zsh.enable {
    programs.zsh.enable = true;
  };

  config.hm = lib.mkIf config.features.zsh.enable {
    # See: https://github.com/starship.
    programs.starship = {
      enable = true;

      # TODO: Make this configurable.
      enableBashIntegration = true;
      enableZshIntegration = true;

      settings = {
        add_newline = false;
        directory = {
          truncation_length = 2;
          format = "[$path]($style)[$read_only]($read_only_style) ";
        };
      };
    };

    # See: https://github.com/junegunn/fzf.
    programs.fzf = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
    };

    # See: https://github.com/ajeetdsouza/zoxide.
    programs.zoxide.enable = true;

    # See: https://github.com/lsd-rs/lsd.
    programs.lsd = {
      enable = true;
      enableAliases = false;
    };

    # See: https://github.com/sharkdp/bat.
    programs.bat.enable = true;

    programs.zsh = {
      enable = true;

      dotDir = ".config/zsh";
      autosuggestion.enable = true;
      enableCompletion = true;
      syntaxHighlighting.enable = false;

      historySubstringSearch = {
        enable = true;
        searchUpKey = ["^[j" "^[[A" "$terminfo[kcuu1]"];
        searchDownKey = ["^[k" "^[[B" "$terminfo[kcud1]"];
      };

      sessionVariables = {
        TERM = "xterm-256color";
      };

      shellAliases = {
        # Alias `code` to `code-insiders`.
        code = "code-insiders";

        # Misc aliases.

        mv = "mv -iv";
        rm = "rm -I";
        cp = "cp -iv";
        ln = "ln -iv";
        mkdir = "mkdir -pv";

        ls = "lsd";
        lsl = "lsd -lF";
        lsa = "lsd -laF";
        # Just for fun.
        lalala = "lsa";

        ".." = "cd ..";
        "..." = "cd ../..";
        "...." = "cd ../../..";
        "....." = "cd ../../../..";

        cl = "clear";
        please = "sudo $(fc -ln -1)";
        dev = "nix develop --impure -c $SHELL";

        # Remove the currently linked smartcard from the GPG agent. Useful in a
        # multi-smartcard setup when the card is different than the last one
        # used.
        gpg-unlink-smartcard = "gpg-connection-agent \"scd serialno\" \"learn --force\" /bye";

        # Nix/OS aliases.

        oss = "nh os switch";
        osb = "nh os boot";
        osu = "nh os boot -u";
        osc = "nh clean all --keep 5";

        # Git aliases.

        gits = "git status";
        gitd = "git diff";
        gita = "git add";
        gitc = "git commit";
        gitg = "git graph";
        # Fast-forward to the latest stuff.
        gitfresh = "git fetch && git pull --ff-only";
        # Get latest state of the current branch from remote, and don't care about
        # any local changes.
        gitgud = "git fetch && git_reset_current_branch_to_origin";
        # Rebase the current branch on top of the latest state of the main branch.
        gitbased = "git fetch --all && git rebase -i origin/\"$(git_main_branch)\"";
        # Delete all local branches that are no longer present on remote.
        gitclean = "git_clean_gone_branches";
      };

      initExtra = ''
        confirm() {
          read "response?''${1:-Are you sure? [y/N]} "
          case "$response" in
            [yY][eE][sS]|[yY])
                true
                ;;
            *)
                false
                ;;
          esac
        }

        git_main_branch() {
          git branch -r | grep -Po "HEAD -> \K.*$" | sed -e 's|^origin/||'
        }

        git_current_branch() {
          git symbolic-ref -q "HEAD" | sed -e 's|^refs/heads/||'
        }

        git_gone_branches() {
          git branch -vv | grep gone | awk '{print $1}'
        }

        # Fetch and replace local branch with origin.
        git_reset_current_branch_to_origin() {
          local current_branch
          current_branch="$(git_current_branch)"
          if confirm "Hard reset current branch to origin/$current_branch? [y/N]"; then
            git reset --hard origin/"$current_branch"
          fi
        }

        # Delete all branches that are no longer present on remote.
        git_clean_gone_branches() {
          if confirm "Delete all branches that are no longer present on remote? [y/N]"; then
            if [ -z "$(git_gone_branches)" ]; then
              echo "No branches to delete."
              return 0
            fi

            git_gone_branches | xargs git branch -D
          fi
        }
      '';

      history = {
        size = 1000000;
        save = 1000000;
        extended = true;
      };

      antidote = {
        enable = true;
        plugins = [
          "MichaelAquilina/zsh-you-should-use"
          "zdharma-continuum/fast-syntax-highlighting kind:defer"
        ];
      };
    };
  };
}
