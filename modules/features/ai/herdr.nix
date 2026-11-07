{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  herdr = inputs.self.wrappers.herdr.wrap {
    inherit pkgs;
    # Set environment variables as weak default, such that nested processes
    # don't re-resolve 1Password references unnecessarily.
    envDefault = import ./env.nix;
  };
in {
  config.hm = lib.mkIf config.features.ai.enable {
    home.packages = [herdr];

    xdg.configFile."herdr/config.toml".source = (pkgs.formats.toml {}).generate "herdr-config.toml" {
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
  };
}
