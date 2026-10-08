{pkgs}: let
  billionContextPi = pkgs.callPackage ./billion-context-pi.nix {};
  piHerdrSubagents = pkgs.callPackage ./pi-herdr-subagents.nix {};
  piPermissionSystem = pkgs.callPackage ./pi-permission-system.nix {};
  pluginRoot = "${piHerdrSubagents}/herdr-plugin";

  herdrWithSubagents = pkgs.writeShellApplication {
    name = "herdr";
    runtimeInputs = [pkgs.jq];
    text = ''
      # Keep the version-matched subagent plugin linked without modifying unrelated plugins.
      plugin_list="$(${pkgs.lib.getExe pkgs.herdr} plugin list --json 2>/dev/null || true)"
      if ! printf '%s' "$plugin_list" | ${pkgs.lib.getExe pkgs.jq} -e \
        --arg plugin_root '${pluginRoot}' \
        'any(.result.plugins[]?; .plugin_root == $plugin_root and .enabled == true)' \
        >/dev/null 2>&1; then
        ${pkgs.lib.getExe pkgs.herdr} plugin link '${pluginRoot}' --enabled >/dev/null
      fi

      exec ${pkgs.lib.getExe pkgs.herdr} "$@"
    '';
  };
in {
  inherit billionContextPi herdrWithSubagents piHerdrSubagents piPermissionSystem;
}
