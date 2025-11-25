{
  inputs,
  config,
  lib,
  pkgs,
  hmConfig,
  ...
}: {
  options.features.firefox.enable = lib.mkOption {
    description = ''
      Whether to enable Firefox.
    '';
    type = lib.types.bool;
    default = false;
    example = true;
  };

  config.hm = lib.mkIf config.features.firefox.enable {
    home.sessionVariables = {
      BROWSER = "firefox-devedition";
      MOZ_ENABLE_WAYLAND = 1;
      MOZ_LEGACY_PROFILES = 1;
    };

    xdg.mimeApps = {
      enable = true;

      defaultApplications = {
        "applications/x-www-browser" = ["firefox-devedition.desktop"];
        "text/html" = ["firefox-devedition.desktop"];
        "text/xml" = ["firefox-devedition.desktop"];
        "x-scheme-handler/about" = ["firefox-devedition.desktop"];
        "x-scheme-handler/http" = ["firefox-devedition.desktop"];
        "x-scheme-handler/https" = ["firefox-devedition.desktop"];
      };
    };

    programs.firefox = {
      enable = true;

      package = pkgs.wrapFirefox pkgs.firefox-devedition-unwrapped {
        extraPolicies = {
          DisableFirefoxAccounts = true;
          DisableFirefoxStudies = true;
          DisablePocket = true;
          DisableSetDesktopBackground = true;
          DisableTelemetry = true;
          PasswordManagerEnabled = false;
          PromptForDownloadLocation = true;
          FirefoxHome.Pocket = false;
          FirefoxHome.Snippets = false;
          OverrideFirstRunPage = "";
        };
      };

      profileVersion = null;
      profiles = {
        "dev-edition-default" = {
          id = 0;
          path = "${hmConfig.home.username}";
        };

        "${hmConfig.home.username}" = {
          id = 1;
          name = "${hmConfig.home.username}";

          userChrome = ''
            @import "firefox-gnome-theme/userChrome.css";
            @import "firefox-gnome-theme/theme/colors/dark.css";

            /* Hide Firefox View button */
            #firefox-view-button {
              display: none;
            }
          '';
          userContent = ''
            @import "firefox-gnome-theme/userContent.css";
          '';

          bookmarks = {
            force = true;

            settings = [
              {
                name = "Toolbar";
                toolbar = true;
                bookmarks = [
                  {
                    name = "Search";
                    bookmarks = [
                      {
                        name = "Kagi";
                        keyword = "kg";
                        url = "https://kagi.com";
                      }
                      {
                        name = "DuckDuckGo";
                        keyword = "dg";
                        url = "https://duckduckgo.com";
                      }
                    ];
                  }
                  {
                    name = "NixOS";
                    bookmarks = [
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
                    bookmarks = [
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
                    bookmarks = [
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
              }
            ];
          };

          extensions = {
            packages = let
              # FIXME: For some reason, `firefox-addons` doesn't respect or know
              # about `nixpkgs.config.allowUnfree` being set to `true`, and so
              # unfree plugins are blocked from evaluation. This is a workaround
              # to enable unfree plugins. See:
              # https://github.com/pluiedev/flake/blob/main/users/leah/programs/firefox/default.nix.
              gaslight = pkgs: pkgs.overrideAttrs {meta.license.free = true;};
            in
              with inputs.firefox-addons.packages.${pkgs.stdenv.hostPlatform.system};
                map gaslight [
                  decentraleyes
                  don-t-fuck-with-paste
                  clearurls
                  consent-o-matic
                  cookie-autodelete
                  enhanced-h264ify
                  kagi-search
                  onepassword-password-manager
                  privacy-badger
                  ublock-origin
                ];
          };

          search = {
            force = true;

            default = "kagi";
            order = [
              "kagi"
              "ddg"
              "youtube"
              "github"
              "nixos-options"
              "nix-packages"
              "home-manager-options"
              "hacker-news"
            ];

            engines = {
              amazondotcom-us.metaData.hidden = true;
              bing.metaData.hidden = true;
              ebay.metaData.hidden = true;
              google.metaData.hidden = true;
              qwant.metaData.hidden = true;

              kagi = {
                name = "Kagi";
                icon = "https://kagi.com/favicon.ico";
                updateInterval = 24 * 60 * 60 * 1000;
                definedAliases = ["@k"];
                urls = [
                  {
                    template = "https://kagi.com/search";
                    params = [
                      {
                        name = "q";
                        value = "{searchTerms}";
                      }
                    ];
                  }
                ];
              };

              youtube = {
                name = "YouTube";
                icon = "https://youtube.com/favicon.ico";
                updateInterval = 24 * 60 * 60 * 1000;
                definedAliases = ["@yt"];
                urls = [
                  {
                    template = "https://www.youtube.com/results";
                    params = [
                      {
                        name = "search_query";
                        value = "{searchTerms}";
                      }
                    ];
                  }
                ];
              };

              github = {
                name = "GitHub";
                icon = "https://github.com/favicon.ico";
                updateInterval = 24 * 60 * 60 * 1000;
                definedAliases = ["@gh"];

                urls = [
                  {
                    template = "https://github.com/search";
                    params = [
                      {
                        name = "q";
                        value = "{searchTerms}";
                      }
                    ];
                  }
                ];
              };

              nix-packages = {
                name = "Nix Packages";
                icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                definedAliases = ["@np"];
                urls = [
                  {
                    template = "https://search.nixos.org/packages";
                    params = [
                      {
                        name = "type";
                        value = "packages";
                      }
                      {
                        name = "query";
                        value = "{searchTerms}";
                      }
                    ];
                  }
                ];
              };

              nixos-options = {
                name = "NixOS Options";
                icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                definedAliases = ["@no"];
                urls = [
                  {
                    template = "https://search.nixos.org/options";
                    params = [
                      {
                        name = "channel";
                        value = "unstable";
                      }
                      {
                        name = "query";
                        value = "{searchTerms}";
                      }
                    ];
                  }
                ];
              };

              home-manager-options = {
                name = "Home Manager Options";
                icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                definedAliases = ["@hm"];

                url = [
                  {
                    template = "https://mipmip.github.io/home-manager-option-search/";
                    params = [
                      {
                        name = "query";
                        value = "{searchTerms}";
                      }
                    ];
                  }
                ];
              };

              hacker-news = {
                name = "Hacker News";
                icon = "https://hn.algolia.com/favicon.ico";
                updateInterval = 24 * 60 * 60 * 1000;
                definedAliases = ["@hn"];

                url = [
                  {
                    template = "https://hn.algolia.com/";
                    params = [
                      {
                        name = "query";
                        value = "{searchTerms}";
                      }
                    ];
                  }
                ];
              };
            };
          };

          settings =
            {
              "intl.accept_languages" = "en-US,en";

              # Disable translation for Swiss German, German, French, and Spanish.
              # See: https://en.wikipedia.org/wiki/IETF_language_tag.
              "browser.translations.neverTranslateLanguages" = "gsw,de,fr,es";

              # For Firefox GNOME theme.
              "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
              "browser.uidensity" = 0;
              "svg.context-properties.content.enabled" = true;
              "browser.theme.dark-private-windows" = false;
              "widget.gtk.rounded-bottom-corners.enabled" = true;
              "layers.acceleration.force-enabled" = true; # Wayland fix.
              "gnomeTheme.hideSingleTab" = true;
              "gnomeTheme.normalWidthTabs" = true;
              "gnomeTheme.bookmarksToolbarUnderTabs" = true;

              # Misc.
              "apps.update.auto" = false;
              "browser.disableResetPrompt" = true;
              "browser.download.panel.shown" = true;
              "browser.download.useDownloadDir" = false;
              "browser.toolbars.bookmarks.visibility" = "always";

              # Make new tab page simple.
              "browser.newtabpage.enabled" = false;
              "browser.newtabpage.introShown" = false;
              "browser.newtabpage.pinned" = [];
              "browser.newtabpage.enhanced" = false;

              # Save history on exit.
              "privacy.clearOnShutdown.history" = false;
              "signon.rememberSignons" = false;

              # Don't predict network requests.
              "network.predictor.enabled" = false;
              "browser.urlbar.speculativeConnect.enabled" = false;

              # Resume previous session on startup.
              "browser.startup.page" = 3;
              "browser.startup.homepage" = "https://kagi.com";

              # Opt out of firefox studies.
              "app.normandy.enabled" = false;
              "app.shield.optoutstudies.enabled" = false;

              # Privacy & security.
              "privacy.donottrackheader.enabled" = true;
              "privacy.trackingprotection.enabled" = true;
              "privacy.trackingprotection.socialtracking.enabled" = true;
              "privacy.userContext.enabled" = true;
              "privacy.userContext.ui.enabled" = true;
              "privacy.firstparty.isolate" = true;
              "dom.security.https_only_mode" = true;

              "browser.send_pings" = false; # Don't respect <a ping=...>.

              "beacon.enabled" = false; # Disable bluetooth.
              "device.sensors.enabled" = false; # Disable device sensors.
              "geo.enabled" = false; # Disable geolocation.

              # Disable telemetry.
              "toolkit.telemetry.archive.enabled" = false;
              "toolkit.telemetry.enabled" = false;
              "toolkit.telemetry.server" = "";
              "toolkit.telemetry.unified" = false;
              "extensions.webcompat-reporter.enabled" = false;
              "datareporting.policy.dataSubmissionEnabled" = false;
              "datareporting.healthreport.uploadEnabled" = false;
              "browser.ping-centre.telemetry" = false;
              "browser.urlbar.eventTelemetry.enabled" = false;
              "browser.tabs.crashReporting.sendReport" = false;

              # Disable some useless stuff.
              "browser.shell.checkDefaultBrowser" = false;
              "browser.shell.defaultBrowserCheckCount" = 1;
              "extensions.pocket.enabled" = false;
              "extensions.abuseReport.enabled" = false;
              "extensions.formautofill.creditCards.enabled" = false;
              "identity.fxaccounts.enabled" = false;
              "identity.fxaccounts.toolbar.enabled" = false;
              "identity.fxaccounts.pairing.enabled" = false;
              "identity.fxaccounts.commands.enabled" = false;
              "browser.contentblocking.report.lockwise.enabled" = false;
              "browser.uitour.enabled" = false;
              "browser.newtabpage.activity-stream.showSponsored" = false;
              "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
              "browser.newtabpage.activity-stream.improvesearch.topSiteSearchShortcuts" = false;
              "browser.newtabpage.activity-stream.section.highlights.includePocket" = false;

              # Disable Firefox View.
              "browser.tabs.firefox-view" = false;
              "browser.tabs.firefox-view-next" = false;

              # Disable annoying web features.
              "dom.push.enabled" = false;
              "dom.push.connection.enabled" = false;
              "dom.battery.enabled" = false;

              # Enable DRM (Widevine).
              "media.eme.enabled" = true;
              "media.gmp-widevinecdm.visible" = true;
              "media.gmp-widevinecdm.enabled" = true;
              "media.eme.encrypted-media-encryption-scheme.enabled" = true;
            }
            # Aarch64 Widevine support.
            // (
              if pkgs.stdenv.hostPlatform.isAarch64
              then {
                "media.gmp-widevinecdm.version" = pkgs.widevinecdm-aarch64.version;
                "media.gmp-widevinecdm.autoupdate" = false;
              }
              else {}
            );
        };
      };
    };

    # Widevine Support.
    home.file."firefox-widevinecdm" = lib.mkIf pkgs.stdenv.hostPlatform.isAarch64 {
      enable = true;

      target = ".mozilla/firefox/${hmConfig.home.username}/gmp-widevinecdm";
      source = pkgs.runCommandLocal "firefox-widevinecdm" {} ''
        out=$out/${pkgs.widevinecdm-aarch64.version}
        mkdir -p $out
        ln -s ${pkgs.widevinecdm-aarch64}/manifest.json $out/manifest.json
        ln -s ${pkgs.widevinecdm-aarch64}/libwidevinecdm.so $out/libwidevinecdm.so
      '';
      recursive = true;
    };

    home.file."firefox-theme" = {
      enable = true;

      target = ".mozilla/firefox/${hmConfig.home.username}/chrome/firefox-gnome-theme";
      source = inputs.firefox-gnome-theme;
    };
  };
}
