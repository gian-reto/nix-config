{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.helium;

  # Resolve external extensions and add them to the Nix store.
  fetchExtension = {
    hash,
    id,
    url,
    version,
  }:
    pkgs.fetchurl {
      inherit url hash;
      name = "${id}-${version}.crx";
    };
  externalExtensionFiles = lib.listToAttrs (map (extension: {
      name = "net.imput.helium/External Extensions/${extension.id}.json";
      value.text = lib.toJSON {
        external_crx = "${fetchExtension {inherit (extension) hash id url version;}}";
        external_version = extension.version;
      };
    })
    cfg.externalExtensions);

  policyAttrs =
    {
      ExtensionInstallAllowlist = map (extension: extension.id) cfg.externalExtensions;
    }
    // cfg.extraPolicies;

  # Merge preferences into the `Default` profile, creating it if it doesn't exist.
  configDir = "${config.xdg.configHome}/net.imput.helium";
  preferencesJson = pkgs.writeText "helium-preferences.json" (lib.toJSON cfg.preferences);
  mergePreferencesScript =
    if cfg.preferences != {}
    then
      pkgs.writeShellScript "merge-helium-preferences" ''
        prefs_dir="${configDir}/Default"
        prefs_file="$prefs_dir/Preferences"
        ${pkgs.coreutils}/bin/mkdir -p "$prefs_dir"
        if [ -f "$prefs_file" ]; then
          merged=$(${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$prefs_file" "${preferencesJson}" 2>/dev/null)
          if [ -n "$merged" ]; then
            printf '%s\n' "$merged" > "$prefs_file.tmp" && ${pkgs.coreutils}/bin/mv "$prefs_file.tmp" "$prefs_file"
          fi
        else
          ${pkgs.coreutils}/bin/cp "${preferencesJson}" "$prefs_file"
        fi
      ''
    else null;

  # Make wrapped `helium` package with extra flags and preferences.
  wrapperFlagArguments = lib.concatMapStringsSep " " (flag: "--add-flags ${lib.escapeShellArg flag}") cfg.extraFlags;
  heliumWrapped =
    if cfg.extraFlags == [] && cfg.preferences == {}
    then cfg.package
    else
      pkgs.symlinkJoin {
        name = "helium-wrapped";
        paths = [cfg.package];
        nativeBuildInputs = [pkgs.makeWrapper];
        meta.mainProgram = "helium";
        postBuild = ''
          wrapProgram $out/bin/helium ${wrapperFlagArguments}${lib.optionalString (cfg.preferences != {}) " --run ${lib.escapeShellArg mergePreferencesScript}"}
        '';
      };
in {
  options.programs.helium = {
    enable = lib.mkEnableOption "Helium browser";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.helium or (throw "programs.helium.package must be set because pkgs.helium is unavailable.");
      defaultText = lib.literalExpression "pkgs.helium";
      description = "The Helium browser package to use.";
    };

    externalExtensions = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          id = lib.mkOption {
            type = lib.types.str;
            description = "Extension ID from the Chrome Web Store URL.";
          };
          hash = lib.mkOption {
            type = lib.types.str;
            description = "Nix hash of the extension CRX file.";
          };
          version = lib.mkOption {
            type = lib.types.str;
            description = "Extension version from the CRX manifest.";
          };
          url = lib.mkOption {
            type = lib.types.str;
            description = "Pinned URL of the extension CRX file.";
          };
        };
      });
      default = [];
      description = "Chromium extensions to install declaratively through External Extensions JSON files.";
      example = lib.literalExpression ''
        [
          {
            id = "aeblfdkhhhdcdjpifhhbdiojplfjncoa";
            hash = "sha256-...";
            version = "8.12.22.17";
            url = "https://clients2.googleusercontent.com/crx/blobs/...";
          }
        ]
      '';
    };

    extraFlags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Additional command-line flags passed to the Helium wrapper.";
      example = ["--force-dark-mode" "--incognito"];
    };

    extraPolicies = lib.mkOption {
      type = lib.types.attrsOf lib.types.json;
      default = {};
      description = "Chromium enterprise policies to apply.";
      example = lib.literalExpression ''
        {
          PasswordManagerEnabled = false;
          BrowserSignin = 0;
        }
      '';
    };

    preferences = lib.mkOption {
      type = lib.types.attrsOf lib.types.json;
      default = {};
      description = "Chromium preferences to merge into the Default profile.";
      example = lib.literalExpression ''
        {
          bookmark_bar.show_on_all_tabs = true;
          browser.show_home_button = true;
        }
      '';
    };

    finalPolicyJson = lib.mkOption {
      type = lib.types.str;
      internal = true;
      default = lib.toJSON policyAttrs;
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [heliumWrapped];

    xdg.configFile = externalExtensionFiles;
  };
}
