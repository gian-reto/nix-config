{
  config,
  lib,
  ...
}: let
  enabledUsers = lib.filterAttrs (_: user: user.programs.helium.enable or false) (config.home-manager.users or {});

  policyFiles = lib.mapAttrs' (name: user:
    lib.nameValuePair "chromium/policies/managed/helium-${name}.json" {
      text = user.programs.helium.finalPolicyJson;
      mode = "0644";
    })
  enabledUsers;
in {
  config = lib.mkIf (enabledUsers != {}) {
    environment.etc = policyFiles;
  };
}
