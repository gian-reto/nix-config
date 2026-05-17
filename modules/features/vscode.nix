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
        "text/plain" = ["code.desktop"];
      };
    };

    programs.vscode = {
      enable = true;

      argvSettings = {
        disable-hardware-acceleration = false;
        enable-crash-reporter = false;
        # Fix keyring integration.
        password-store = "gnome-libsecret";
      };
      mutableExtensionsDir = false;
      profiles = {
        default = {
          enableExtensionUpdateCheck = false;
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
              ms-vscode-remote.remote-containers
              ms-vsliveshare.vsliveshare
              rust-lang.rust-analyzer
              signageos.signageos-vscode-sops
              ziglang.vscode-zig
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
                  dnut.rewrap-revived
                  github.copilot-chat
                  heybourn.headwind
                  mikestead.dotenv
                  mrmlnc.vscode-json5
                  redhat.vscode-yaml
                  solomonkinard.git-blame
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
            "[nix]" = {
              "editor.defaultFormatter" = "kamadorueda.alejandra";
            };
            "[rust]" = {
              "editor.defaultFormatter" = "rust-lang.rust-analyzer";
            };
            "[svelte]" = {
              "editor.defaultFormatter" = "svelte.svelte-vscode";
            };
            "breadcrumbs.enabled" = true;
            "dev.containers.defaultExtensions" = [
              "amatiasq.sort-imports"
              "christian-kohler.path-intellisense"
              "dnut.rewrap-revived"
              "esbenp.prettier-vscode"
              "github.copilot-chat"
              "jnoortheen.nix-ide"
              "kamadorueda.alejandra"
              "ms-vscode-remote.remote-containers"
              "rust-lang.rust-analyzer"
              "solomonkinard.git-blame"
              "svelte.svelte-vscode"
              "wayou.vscode-todo-highlight"
            ];
            "dev.containers.dockerComposePath" = lib.getExe pkgs.podman-compose;
            "dev.containers.dockerPath" = lib.getExe pkgs.podman;
            "editor.bracketPairColorization.enabled" = true;
            "editor.codeActionsOnSave" = {
              "source.fixAll" = "explicit";
            };
            "editor.cursorBlinking" = "expand";
            "editor.defaultFormatter" = "esbenp.prettier-vscode";
            "editor.fastScrollSensitivity" =
              if config.laptop.enable
              then 0.9
              else 3;
            "editor.fontFamily" = "${builtins.head osConfig.fonts.fontconfig.defaultFonts.monospace}, 'monospace', monospace";
            "editor.fontLigatures" = true;
            "editor.fontSize" = 14;
            "editor.formatOnPaste" = false;
            "editor.formatOnSave" = true;
            "editor.formatOnType" = false;
            "editor.guides.bracketPairs" = true;
            "editor.guides.indentation" = true;
            "editor.inertialScroll" =
              if config.laptop.enable
              then true
              else false;
            "editor.inlineSuggest.enabled" = true;
            "editor.insertSpaces" = true;
            "editor.minimap.enabled" = true;
            "editor.minimap.renderCharacters" = true;
            "editor.mouseWheelScrollSensitivity" =
              if config.laptop.enable
              then 0.3
              else 1;
            "editor.overviewRulerBorder" = true;
            "editor.renderLineHighlight" = "line";
            "editor.smoothScrolling" = true;
            "editor.suggestSelection" = "first";
            "editor.tabSize" = 2;
            "editor.wordWrap" = "off";
            "explorer.compactFolders" = false;
            "explorer.confirmDelete" = true;
            "files.associations" = {
              "*.svg" = "html";
            };
            "github.copilot.enable" = {
              "*" = true;
              "asciidoc" = true;
              "markdown" = true;
              "plaintext" = false;
              "scminput" = false;
              "typescript" = true;
              "yaml" = true;
            };
            "js/ts.updateImportsOnFileMove.enabled" = "always";
            "json.schemaDownload.trustedDomains" = {
              "https://biomejs.dev" = true;
              "https://developer.microsoft.com/json-schemas/" = true;
              "https://json-schema.org/" = true;
              "https://json.schemastore.org/" = true;
              "https://raw.githubusercontent.com/devcontainers/spec/" = true;
              "https://raw.githubusercontent.com/microsoft/vscode/" = true;
              "https://schemastore.azurewebsites.net/" = true;
              "https://www.schemastore.org/" = true;
            };
            "nix.enableLanguageServer" = true;
            "nix.serverPath" = "${lib.getExe pkgs.nil}";
            "nix.serverSettings" = {
              nil.formatting.command = [
                "${lib.getExe pkgs.alejandra}"
              ];
            };
            "redhat.telemetry.enabled" = false;
            "security.workspace.trust.banner" = "never";
            "security.workspace.trust.enabled" = false;
            "security.workspace.trust.startupPrompt" = "never";
            "security.workspace.trust.untrustedFiles" = "open";
            "telemetry.telemetryLevel" = "off";
            "terminal.integrated.cursorBlinking" = true;
            "terminal.integrated.defaultProfile.linux" = "zsh";
            "terminal.integrated.enableVisualBell" = false;
            "terminal.integrated.fastScrollSensitivity" = 3;
            "terminal.integrated.fontFamily" = builtins.head osConfig.fonts.fontconfig.defaultFonts.monospace;
            # Error `GCVM_L2_PROTECTION_FAULT_STATUS` in `amdgpu` caused by VSCode.
            # See: https://github.com/microsoft/vscode/issues/238088.
            "terminal.integrated.gpuAcceleration" = "off";
            "terminal.integrated.mouseWheelScrollSensitivity" = 1.2;
            "terminal.integrated.scrollback" = 100000;
            "terminal.integrated.smoothScrolling" = true;
            "update.mode" = "none";
            "window.autoDetectColorScheme" = true;
            "window.commandCenter" = true;
            "window.dialogStyle" = "native";
            "window.menuBarVisibility" = "classic";
            "window.restoreWindows" = "all";
            "window.titleBarStyle" = "custom";
            "workbench.colorTheme" = "Adwaita Light";
            "workbench.editor.tabActionLocation" = "right";
            "workbench.iconTheme" = "ayu";
            "workbench.list.smoothScrolling" = true;
            "workbench.panel.defaultLocation" = "bottom";
            "workbench.preferredDarkColorTheme" = "Adwaita Dark";
            "workbench.secondarySideBar.defaultVisibility" = "hidden";
            "workbench.sideBar.location" = "left";
            "workbench.startupEditor" = "newUntitledFile";
          };
        };
      };
    };
  };
}
