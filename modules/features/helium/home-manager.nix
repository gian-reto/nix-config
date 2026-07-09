{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.helium;

  archInfo = let
    platform = pkgs.stdenv.hostPlatform;
  in
    if platform.isAarch64
    then {
      arch = "arm64";
      osArch = "aarch64";
      naclArch = "aarch64";
    }
    else if platform.isx86_64
    then {
      arch = "x64";
      osArch = "x86_64";
      naclArch = "x86-64";
    }
    else throw "Helium extension fetching is only supported on aarch64-linux and x86_64-linux.";

  # Resolve extensions and external extensions, and generate policy files for the latter.
  extensionProductVersion = cfg.package.upstream-info.version or (throw "programs.helium.package must expose upstream-info.version.");
  fetchExtension = {
    id,
    hash,
  }:
    pkgs.fetchurl {
      name = "${id}.crx";
      url = "https://clients2.google.com/service/update2/crx?response=redirect&os=linux&arch=${archInfo.arch}&os_arch=${archInfo.osArch}&nacl_arch=${archInfo.naclArch}&prod=chromiumcrx&prodchannel=stable&prodversion=${extensionProductVersion}&acceptformat=crx3&x=id%3D${id}%26installsource%3Dondemand%26uc";
      inherit hash;
    };
  unpackExtension = {
    id,
    hash,
  }:
    pkgs.runCommand "helium-ext-${id}"
    {
      nativeBuildInputs = [pkgs.unzip];
      src = fetchExtension {inherit id hash;};
    }
    ''
      mkdir -p $out
      unzip -q $src -d $out || true
      [ -n "$(ls -A $out 2>/dev/null)" ] || { echo "ERROR: unpacking $src produced no files" >&2; exit 1; }
      rm -rf $out/_metadata
    '';
  resolvedExtensions =
    map (spec: {
      inherit (spec) id;
      unpacked = unpackExtension {inherit (spec) id hash;};
    })
    cfg.extensions;
  resolvedExternalExtensions =
    map (spec: {
      inherit (spec) id version;
      crx = fetchExtension {inherit (spec) id hash;};
    })
    cfg.externalExtensions;
  externalExtensionFiles = lib.listToAttrs (map (extension: {
      name = "net.imput.helium/External Extensions/${extension.id}.json";
      value.text = lib.toJSON {
        external_crx = "${extension.crx}";
        external_version = extension.version;
      };
    })
    resolvedExternalExtensions);
  managedExtensionIds = map (extension: extension.id) (cfg.extensions ++ cfg.externalExtensions);
  policyAttrs =
    {
      ExtensionInstallAllowlist = managedExtensionIds;
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

  # Make wrapped `helium` package with extensions and extra flags, and preferences.
  loadExtensionFlags =
    if resolvedExtensions != []
    then ["--load-extension=${lib.concatStringsSep "," (map (extension: "${extension.unpacked}") resolvedExtensions)}"]
    else [];
  wrapperFlags = loadExtensionFlags ++ cfg.extraFlags;
  wrapperFlagArguments = lib.concatMapStringsSep " " (flag: "--add-flags ${lib.escapeShellArg flag}") wrapperFlags;
  heliumWrapped =
    if wrapperFlags == [] && cfg.preferences == {}
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

    extensions = lib.mkOption {
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
        };
      });
      default = [];
      description = "Chromium extensions to install declaratively through load-extension flags.";
      example = lib.literalExpression ''
        [
          {
            id = "nngceckbapebfimnlniiiahkandclblb";
            hash = "sha256-...";
          }
        ]
      '';
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
