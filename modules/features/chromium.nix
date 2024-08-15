{
  config,
  lib,
  pkgs,
  ...
}: {
  options.features.chromium.enable = lib.mkOption {
    description = ''
      Whether to enable Chromium.
    '';
    type = lib.types.bool;
    default = false;
    example = true;
  };

  config.hm = lib.mkIf config.features.chromium.enable {
    programs.chromium = {
      enable = true;

      package = pkgs.ungoogled-chromium;
      commandLineArgs = [
        # `ungoogled-chromium` flags.
        "--bookmark-bar-ntp=never"
        "--custom-ntp=https://kagi.com"
        "--disable-search-engine-collection"
        "--disable-sharing-hub"
        "--disable-top-sites"
        # Necessary to install addons on ungoogled-chromium. See:
        # https://github.com/NeverDecaf/chromium-web-store?tab=readme-ov-file#chromium-web-store.
        "--extension-mime-request-handling=always-prompt-for-install"
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

        # Miscellaneous flags.
        "--disable-background-networking"
        "--disable-sync"
        "--disable-features=MediaRouter"
        "--enable-features=UseOzonePlatform,WebUIDarkMode"
        "--no-default-browser-check"
        "--ozone-platform=wayland"
      ];
      extensions = [
        {id = "aeblfdkhhhdcdjpifhhbdiojplfjncoa";} # 1Password
        {id = "ldpochfccmkkmhdbclfhpagapcfdljkj";} # Decentraleyes
        {id = "cdglnehniifkbagbbombnjghhcihifij";} # Kagi Search
        {id = "cjpalhdlnbpafiamejdnhcphjbkeiagm";} # uBlock Origin
      ];
    };
  };
}
