{
  config,
  lib,
  pkgs,
  ...
}: let
  herdrConfig = (pkgs.formats.toml {}).generate "herdr-config.toml" {
    onboarding = false;

    theme = {
      custom = {
        accent = "#81d0ff";
        surface_dim = "#1e1e1e";
      };
      name = "terminal";
    };

    ui = {
      show_agent_labels_on_pane_borders = true;
      sidebar.agents.rows = [
        ["state_icon" "machine" "workspace" "tab"]
        ["agent" "state_text"]
      ];
      status_indicators = "symbols";
    };

    update = {
      manifest_check = false;
      version_check = false;
    };
  };
in {
  config.hm = lib.mkIf config.features.ai.enable {
    home.packages = [pkgs.herdr];

    xdg.configFile."herdr/config.toml".source = herdrConfig;
  };
}
