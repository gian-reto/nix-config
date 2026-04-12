{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  pkgsHelium = import inputs.nixpkgs-helium {
    system = pkgs.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  };

  managedPolicies = {
    # Do not check whether Helium is the default browser.
    DefaultBrowserSettingEnabled = false;

    # Do not run background processes if Helium is closed.
    BackgroundModeEnabled = false;

    # Disable promotions, recommendations, and other annoying stuff.
    BrowserSignin = 0;
    FeedbackSurveysEnabled = false;
    MediaRecommendationsEnabled = false;
    PromotionsEnabled = false;
    ShoppingListEnabled = false;
    SyncDisabled = true;

    # Privacy stuff.
    BlockThirdPartyCookies = true;
    DnsOverHttpsMode = "automatic";
    MetricsReportingEnabled = false;
    NetworkPredictionOptions = 2; # Do not predict any network actions.
    SafeBrowsingExtendedReportingEnabled = false;
    UrlKeyedAnonymizedDataCollectionEnabled = false;

    # Sites must ask for access.
    DefaultGeolocationSetting = 3;
    DefaultLocalFontsSetting = 3;
    DefaultNotificationsSetting = 3;
    DefaultSerialGuardSetting = 3;

    # Deny access.
    DefaultClipboardSetting = 2;
    DefaultSensorsSetting = 2;

    # Sandboxing.
    AudioSandboxEnabled = true;
    NetworkServiceSandboxEnabled = true;
    SandboxExternalProtocolBlocked = true;

    # Search provider.
    DefaultSearchProviderEnabled = true;
    DefaultSearchProviderKeyword = "kg";
    DefaultSearchProviderName = "Kagi";
    DefaultSearchProviderNewTabURL = "https://kagi.com";
    DefaultSearchProviderSearchURL = "https://kagi.com/search?q={searchTerms}";
    DefaultSearchProviderSuggestURL = "https://kagi.com/api/autosuggest?q={searchTerms}";
    SearchSuggestEnabled = true;

    # Homepage & new tab page.
    HomepageIsNewTabPage = false;
    HomepageLocation = "https://kagi.com";
    NewTabPageLocation = "https://kagi.com";
    ShowHomeButton = false;

    # Startup behavior.
    RestoreOnStartup = 1; # Restore the last session, see: https://chromeenterprise.google/policies/default-search-provider-enabled/#RestoreOnStartup.

    # Password Manager.
    PasswordLeakDetectionEnabled = false;
    PasswordManagerEnabled = false;
    PasswordSharingEnabled = false;

    # Disable autofill.
    AutofillAddressEnabled = false;
    AutofillCreditCardEnabled = false;

    # Misc. features.
    AlternateErrorPagesEnabled = false;
    AlwaysOpenPdfExternally = false;
    BrowserGuestModeEnabled = false;
    LiveTranslateEnabled = false;
    PromptForDownloadLocation = false;
    QuicAllowed = true;
    SpellcheckEnabled = false;
    TranslateEnabled = false;

    # Bookmarks.
    BookmarkBarEnabled = true;
    ManagedBookmarks = [
      {
        toplevel_name = "Managed";
      }
      {
        name = "Search";
        children = [
          {
            name = "Kagi";
            url = "https://kagi.com";
          }
          {
            name = "DuckDuckGo";
            url = "https://duckduckgo.com";
          }
        ];
      }
      {
        name = "NixOS";
        children = [
          {
            name = "NixOS Options";
            url = "https://search.nixos.org/options";
          }
          {
            name = "Nix Packages";
            url = "https://search.nixos.org/packages";
          }
          {
            name = "Home Manager Options";
            url = "https://home-manager-options.extranix.com";
          }
        ];
      }
      {
        name = "Docs";
        children = [
          {
            name = "DevDocs";
            url = "https://devdocs.io";
          }
          {
            name = "MDN Web Docs";
            url = "https://developer.mozilla.org";
          }
          {
            name = "TypeScript";
            url = "https://www.typescriptlang.org/docs/";
          }
          {
            name = "Tailwind CSS";
            url = "https://tailwindcss.com/docs";
          }
          {
            name = "Rust";
            url = "https://doc.rust-lang.org";
          }
          {
            name = "Kotlin";
            url = "https://kotlinlang.org/docs";
          }
          {
            name = "Kubernetes";
            url = "https://kubernetes.io/docs";
          }
          {
            name = "Nix";
            url = "https://nixos.org/manual/nix/stable";
          }
          {
            name = "NixOS";
            url = "https://nixos.org/manual/nixos/stable";
          }
        ];
      }
      {
        name = "Tools";
        children = [
          {
            name = "Excalidraw";
            url = "https://excalidraw.com";
          }
          {
            name = "emn178/online-tools";
            url = "https://emn178.github.io/online-tools/";
          }
          {
            name = "Tree";
            url = "https://tree.nathanfriend.io";
          }
        ];
      }
    ];
  };
in {
  options.features.helium.enable = lib.mkOption {
    description = ''
      Whether to enable Helium browser.
    '';
    type = lib.types.bool;
    default = false;
    example = true;
  };

  config = lib.mkIf config.features.helium.enable {
    # Whitelist Helium in 1Password's supported browsers.
    features.op.allowedBrowsers = lib.mkIf config.features.op.enable ["helium"];

    # Import the `nixpille-helium` home-manager module.
    hmModules = [inputs.helium.homeModules.default];

    os.environment.etc."chromium/policies/managed/helium.json".text = builtins.toJSON managedPolicies;

    hm = {
      programs.helium = {
        enable = true;
        package = pkgsHelium.helium.override {
          enableWideVine = true;
        };

        commandLineArgs = [
          "--enable-features=WaylandWindowDecorations"
          "--ozone-platform-hint=auto"

          # Currently disabled due to: https://issues.chromium.org/issues/324994866.
          #
          # "--disable-background-networking"

          # Misc flags.
          "--disable-search-engine-collection"
          "--disable-sharing-hub"
          "--disable-top-sites"
          "--force-dark-mode"
          "--fingerprinting-canvas-image-data-noise"
          "--fingerprinting-canvas-measuretext-noise"
          "--fingerprinting-client-rects-noise"
          "--hide-sidepanel-button"
          "--no-pings"
          "--popups-to-tabs"
          "--remove-tabsearch-button"
          "--show-avatar-button=never"
          "--tab-hover-cards=tooltip"

          # Performance flags.
          "--enable-gpu-rasterization"
          "--enable-oop-rasterization"
          "--enable-zero-copy"
          "--enable-accelerated-video-decode"
          "--ignore-gpu-blocklist"
        ];

        extensions = [
          {id = "aeblfdkhhhdcdjpifhhbdiojplfjncoa";} # 1Password Password Manager.
          {id = "cdglnehniifkbagbbombnjghhcihifij";} # Kagi Search.
          {id = "efaagigdgamehbpimpiagfpoihlkgamh";} # Don't Fuck With Paste.
          {id = "kceglpglilklghkgofolieongaolnaob";} # Cookie AutoDelete.
          {id = "ldpochfccmkkmhdbclfhpagapcfdljkj";} # Decentraleyes.
          {id = "mdjildafknihdffpkfmmpnpoiajfjnjd";} # Consent-O-Matic.
          {id = "omkfmpieigblcllmkgbflkikinpkodlk";} # Enhanced h264ify.
        ];

        nativeMessagingHosts = let
          onepassword = pkgs.writeTextDir "etc/chromium/native-messaging-hosts/com.1password.1password.json" (
            lib.toJSON {
              name = "com.1password.1password";
              description = "1Password BrowserSupport";
              path = "/run/wrappers/bin/1Password-BrowserSupport";
              type = "stdio";
              allowed_origins = [
                "chrome-extension://aeblfdkhhhdcdjpifhhbdiojplfjncoa/"
                "chrome-extension://bkpbhnjcbehoklfkljkkbbmipaphipgl/"
                "chrome-extension://dppgmdbiimibapkepcbdbmkaabgiofem/"
                "chrome-extension://gejiddohjgogedgjnonbofjigllpkmbf/"
                "chrome-extension://hjlinigoblmkhjejkmbegnoaljkphmgo/"
                "chrome-extension://khgocmkkpikpnmmkgmdnfckapcdkgfaf/"
              ];
            }
          );
        in
          lib.mkIf config.features.op.enable [onepassword];
      };
    };
  };
}
