{pkgs}: {
  billionContextPi = pkgs.callPackage ./billion-context-pi.nix {};
  piApparmorExecutor = pkgs.callPackage ./pi-apparmor-executor {};
  piHerdrPermissions = pkgs.callPackage ./pi-herdr-permissions {};
  piHerdsman = pkgs.callPackage ./pi-herdsman.nix {};
  piPermissionSystem = pkgs.callPackage ./pi-permission-system.nix {};
}
