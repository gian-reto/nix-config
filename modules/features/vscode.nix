{
  inputs,
  config,
  lib,
  pkgs,
  osConfig,
  ...
}: let
  extensions = inputs.nix-vscode-extensions.extensions.${pkgs.stdenv.hostPlatform.system};
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
    xdg.mimeApps = {
      enable = true;

      defaultApplications = {
        "text/plain" = ["code-insiders.desktop"];
      };
    };

    home.file.".vscode-insiders/argv.json" = lib.mkIf config.features.desktop.enable {
      text = builtins.toJSON {
        disable-hardware-acceleration = false;
        enable-crash-reporter = false;
        # Fix keyring integration.
        password-store = "gnome-libsecret";
      };
    };

    programs.vscode = {
      enable = true;

      package = pkgs.vscode-insiders;
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
              mkhl.direnv
              ms-azuretools.vscode-docker
              ms-vsliveshare.vsliveshare
              rust-lang.rust-analyzer
              signageos.signageos-vscode-sops
            ])
            ++ (
              let
                # FIXME: For some reason, `extensions.vscode-marketplace`
                # doesn't respect or know about `nixpkgs.config.allowUnfree`
                # being set to `true`, and so unfree plugins are blocked from
                # evaluation. This is a workaround to enable unfree plugins. See
                # (originally for `firefox`):
                # https://github.com/pluiedev/flake/blob/main/users/leah/programs/firefox/default.nix.
                gaslight = pkg: pkg.overrideAttrs {meta.license.free = true;};
                marketplaceExtensions = with extensions.vscode-marketplace; [
                  amatiasq.sort-imports
                  csstools.postcss
                  dbaeumer.vscode-eslint
                  github.copilot
                  github.copilot-chat
                  heybourn.headwind
                  mikestead.dotenv
                  mrmlnc.vscode-json5
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
                ];
              in
                map gaslight marketplaceExtensions
            )
            ++ (with extensions.open-vsx; [
              piousdeer.adwaita-theme
              sst-dev.opencode
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
            "editor.inertialScroll" =
              if config.laptop.enable
              then true
              else false;
            "editor.smoothScrolling" = true;
            "editor.suggestSelection" = "first";
            "editor.guides.indentation" = true;
            "editor.guides.bracketPairs" = true;
            "editor.bracketPairColorization.enabled" = true;
            "editor.mouseWheelScrollSensitivity" =
              if config.laptop.enable
              then 0.3
              else 1;
            "editor.fastScrollSensitivity" =
              if config.laptop.enable
              then 0.9
              else 3;
            "explorer.confirmDelete" = true;
            "explorer.compactFolders" = false;
            "terminal.integrated.fontFamily" = builtins.head osConfig.fonts.fontconfig.defaultFonts.monospace;
            "terminal.integrated.defaultProfile.linux" = "zsh";
            "terminal.integrated.cursorBlinking" = true;
            "terminal.integrated.enableVisualBell" = false;
            "terminal.integrated.scrollback" = 100000;
            "terminal.integrated.smoothScrolling" = true;
            "terminal.integrated.mouseWheelScrollSensitivity" = 1.2;
            "terminal.integrated.fastScrollSensitivity" = 3;
            # Error `GCVM_L2_PROTECTION_FAULT_STATUS` in `amdgpu` caused by VSCode.
            # See: https://github.com/microsoft/vscode/issues/238088.
            "terminal.integrated.gpuAcceleration" = "off";
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
