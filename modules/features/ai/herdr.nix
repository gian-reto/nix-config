{
  config,
  lib,
  pkgs,
  ...
}: let
  extensionPackages = import ./pi/extensions {inherit pkgs;};

  herdrConfig = (pkgs.formats.toml {}).generate "herdr-config.toml" {
    onboarding = false;

    theme.name = "terminal";

    ui.show_agent_labels_on_pane_borders = true;

    update = {
      manifest_check = false;
      version_check = false;
    };
  };
in {
  config.hm = lib.mkIf config.features.ai.enable {
    home.packages = [extensionPackages.herdrWithSubagents];

    xdg.configFile."herdr/config.toml".source = herdrConfig;
  };
}
