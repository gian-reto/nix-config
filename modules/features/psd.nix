{
  config,
  lib,
  ...
}: {
  # Enables `profile-sync-daemon` for browsers, which uses `tmpfs` so store browser profiles
  # and syncs them to disc periodically.
  config.hm = lib.mkIf config.features.firefox.enable {
    services.psd = {
      enable = true;

      browsers =
        []
        ++ (lib.optionals config.features.firefox.enable ["firefox"]);
      resyncTimer = "15min";
      useBackup = true;
    };
  };
}
