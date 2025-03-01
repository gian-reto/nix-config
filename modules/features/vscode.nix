{
  inputs,
  config,
  lib,
  pkgs,
  osConfig,
  ...
}: let
  extensions = inputs.nix-vscode-extensions.extensions.${pkgs.system};
in {
  options.features.vscode.enable = lib.mkOption {
    description = ''
      Whether to enable VSCode.
    '';
    type = lib.types.bool;
    default = false;
    example = true;
  };

  config.hm = lib.mkIf config.features.vscode.enable {
    home.file.".vscode/argv.json" = lib.mkIf config.features.security.enable {
      text = builtins.toJSON {
        disable-hardware-acceleration = false;
        enable-crash-reporter = false;
        # Fix keyring integration.
        password-store = "gnome-libsecret";
      };
    };

    programs.vscode = {
      enable = true;

      mutableExtensionsDir = true;

      profiles = {
        default = {
          enableExtensionUpdateCheck = true;
          enableUpdateCheck = false;

          extensions =
            (with pkgs.vscode-extensions; [
              bradlc.vscode-tailwindcss
              christian-kohler.path-intellisense
              esbenp.prettier-vscode
              jnoortheen.nix-ide
              kamadorueda.alejandra
              ms-azuretools.vscode-docker
              ms-vsliveshare.vsliveshare
              rust-lang.rust-analyzer
              signageos.signageos-vscode-sops
            ])
            ++ (with extensions.vscode-marketplace; [
              amatiasq.sort-imports
              csstools.postcss
              dbaeumer.vscode-eslint
              github.copilot
              github.copilot-chat
              heybourn.headwind
              mikestead.dotenv
              mrmlnc.vscode-json5
              piousdeer.adwaita-theme
              redhat.vscode-yaml
              s-nlf-fh.glassit
              solomonkinard.git-blame
              stkb.rewrap
              svelte.svelte-vscode
              tamasfe.even-better-toml
              teabyii.ayu
              wayou.vscode-todo-highlight
              wholroyd.jinja
              yzhang.markdown-all-in-one
            ]);

          userSettings = {
            "telemetry.telemetryLevel" = "off";
            "breadcrumbs.enabled" = true;
            "window.commandCenter" = true;
            "window.menuBarVisibility" = "classic";
            "window.restoreWindows" = "all";
            "window.titleBarStyle" = "custom";
            "window.dialogStyle" = "native";
            "workbench.iconTheme" = "ayu";
            "workbench.colorTheme" = "Adwaita Dark";
            "workbench.panel.defaultLocation" = "bottom";
            "workbench.sideBar.location" = "left";
            "workbench.editor.tabActionLocation" = "right";
            "workbench.list.smoothScrolling" = true;
            "workbench.startupEditor" = "newUntitledFile";
            "editor.fontFamily" = "${builtins.head osConfig.fonts.fontconfig.defaultFonts.monospace}, 'monospace', monospace";
            "editor.fontSize" = 14;
            "editor.fontLigatures" = true;
            "editor.tabSize" = 2;
            "editor.insertSpaces" = true;
            "editor.wordWrap" = "off";
            "editor.cursorBlinking" = "expand";
            "editor.formatOnPaste" = false;
            "editor.formatOnSave" = true;
            "editor.formatOnType" = false;
            "editor.codeActionsOnSave" = {
              "source.fixAll" = "explicit";
            };
            "editor.minimap.enabled" = true;
            "editor.minimap.renderCharacters" = true;
            "editor.defaultFormatter" = "esbenp.prettier-vscode";
            "editor.overviewRulerBorder" = true;
            "editor.renderLineHighlight" = "line";
            "editor.inlineSuggest.enabled" = true;
            "editor.smoothScrolling" = true;
            "editor.suggestSelection" = "first";
            "editor.guides.indentation" = true;
            "editor.guides.bracketPairs" = true;
            "editor.bracketPairColorization.enabled" = true;
            "explorer.confirmDelete" = true;
            "explorer.compactFolders" = false;
            "terminal.integrated.fontFamily" = builtins.head osConfig.fonts.fontconfig.defaultFonts.monospace;
            "terminal.integrated.defaultProfile.linux" = "zsh";
            "terminal.integrated.cursorBlinking" = true;
            "terminal.integrated.enableVisualBell" = false;
            "terminal.integrated.scrollback" = 100000;
            "security.workspace.trust.enabled" = false;
            "security.workspace.trust.untrustedFiles" = "open";
            "security.workspace.trust.banner" = "never";
            "security.workspace.trust.startupPrompt" = "never";
            "files.associations" = {
              "*.svg" = "html";
            };
            "github.copilot.enable" = {
              "*" = true;
              "plaintext" = false;
              "markdown" = true;
              "scminput" = false;
              "yaml" = true;
              "typescript" = true;
              "asciidoc" = true;
            };
            "github.copilot.editor.enableAutoCompletions" = true;
            "javascript.updateImportsOnFileMove.enabled" = "always";
            "typescript.updateImportsOnFileMove.enabled" = "always";
            "redhat.telemetry.enabled" = false;
            "[svelte]" = {
              "editor.defaultFormatter" = "svelte.svelte-vscode";
            };
            "[rust]" = {
              "editor.defaultFormatter" = "rust-lang.rust-analyzer";
            };
            "[nix]" = {
              "editor.defaultFormatter" = "kamadorueda.alejandra";
            };
            "nix.enableLanguageServer" = true;
            "nix.serverPath" = "${lib.getExe pkgs.nil}";
            "nix.serverSettings" = {
              nil.formatting.command = [
                "${lib.getExe pkgs.alejandra}"
              ];
            };
          };
        };
      };
    };
  };
}
