# Guide: Adding a Feature

This guide provides a step-by-step process for adding a new `feature` in this NixOS configuration.

For general information about the concept of features, see the [feature overview](./feature_overview.md).

## Steps

1. **Copy the template** from `templates/feature.nix` to `modules/features/<feature_name>.nix`, replacing `<feature_name>` with the name of your feature.
2. **Edit enable option**:
   2.1. Replace `myfeature` in `options.features.myfeature.enable` with the actual name of your feature.
   2.2. Update the `description` field of the option to provide a brief explanation of what the feature does.
3. If the feature requires additional inputs, overlays, or modules, add them in the `config.inputs`, `config.osModules`, and `config.hmModules` attribute sets, respectively. This is rarely needed, as most inputs should be added to the `flake.nix` file at the root of the repository, and additional inputs should only be added conservatively.
4. **Implement the feature**:
   3.1. Add the necessary NixOS configurations in the `config.os` attribute set.
   3.2. If the feature requires Home Manager configurations, add them in the `config.hm` attribute set.
5. **Remove unused flake inputs at the top of the file**.
6. **Add the feature to the imports in `modules/default.nix`** to make it available for enabling in other parts of the configuration.
7. **Enable the feature** in the relevant module (e.g., `modules/gui.nix` for graphical desktop environments) or directly in a host or user configuration file (e.g., `hosts/hostname/default.nix` or `users/username/default.nix`) by setting its `enable` option to `true`.
8. **Check for syntax errors** using the `nil` LSP by running `nil diagnostics <path_to_feature_file>.nix`.
9. **Format the file** using `alejandra` by running `alejandra format <path_to_feature_file>.nix`.
10. **Build and switch to the new configuration** by running `oss` (this is a zsh alias for `nh os switch` and `nixos-rebuild switch`). Alternatively, use the command `osb` to rebuild the configuration without switching to it, but make it the boot default.
11. If there are issues during building, check the logs for errors and fix them accordingly.
