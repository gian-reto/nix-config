{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: {
  options.features.helium.enable = lib.mkOption {
    description = ''
      Whether to enable Helium browser.
    '';
    type = lib.types.bool;
    default = false;
    example = true;
  };

  config = lib.mkIf config.features.helium.enable {
    hmModules = [inputs.helium.homeManagerModules.helium];
    osModules = [inputs.helium.nixosModules.helium];

    os.nixpkgs.overlays = [
      # Instantiate Helium through the host package set so Widevine respects host nixpkgs config.
      (final: _: {
        helium = final.callPackage (inputs.helium + /default.nix) {};
      })
    ];

    # Whitelist Helium in 1Password's supported browsers.
    features.op.allowedBrowsers = lib.mkIf config.features.op.enable ["helium"];

    hm = {
      # Set Helium as the default browser.
      home.sessionVariables = {
        BROWSER = "helium";
      };
      xdg.mimeApps = {
        enable = true;

        defaultApplications = {
          "applications/x-www-browser" = ["helium.desktop"];
          "text/html" = ["helium.desktop"];
          "text/xml" = ["helium.desktop"];
          "x-scheme-handler/about" = ["helium.desktop"];
          "x-scheme-handler/http" = ["helium.desktop"];
          "x-scheme-handler/https" = ["helium.desktop"];
        };
      };

      # 1Password integration.
      xdg.configFile = lib.mkIf config.features.op.enable {
        "net.imput.helium/NativeMessagingHosts/com.1password.1password.json".text = lib.toJSON {
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
        };
      };

      programs.helium = {
        enable = true;
        package = pkgs.helium.override {
          enableWideVine = true;
        };

        extensions = [
          # 1Password Password Manager.
          {
            id = "aeblfdkhhhdcdjpifhhbdiojplfjncoa";
            hash = "sha256-6btg83FaHq2wlEqeypqDwQBTASpELilTAMJXjk52pks=";
          }
          # Kagi Search.
          {
            id = "cdglnehniifkbagbbombnjghhcihifij";
            hash = "sha256-weiUUUiZeeIlz/k/d9VDSKNwcQtmAahwSIHt7Frwh7E=";
          }
          # Decentraleyes.
          {
            id = "ldpochfccmkkmhdbclfhpagapcfdljkj";
            hash = "sha256-SyV7LbLi1v88eWVNeBR4RB8ROnqhfM0HuI+RvLjvmUw=";
          }
          # Consent-O-Matic.
          {
            id = "mdjildafknihdffpkfmmpnpoiajfjnjd";
            hash = "sha256-qdMdkakBMffTyrLcPjN+Q/dfTyto5/3oEuDNJKgTvpg=";
          }
        ];

        extraFlags = [
          "--enable-features=TouchpadOverscrollHistoryNavigation,WaylandWindowDecorations"
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
          "--gtk-version=4"
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

        extraPolicies = {
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

        preferences = {
          bookmark_bar = {
            show_apps_shortcut = false;
            show_managed_bookmarks = true;
            show_on_all_tabs = true;
          };
          browser = {
            enable_spellchecking = false;
            has_seen_welcome_page = true;
            show_home_button = false;
          };
        };
      };
    };
  };
}
