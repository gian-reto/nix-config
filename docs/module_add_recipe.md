# Guide: Adding a Module

This guide provides a step-by-step process for adding a new `module` in this NixOS configuration.

For general information about the concept of modules in this repository, see the [module overview](./module_overview.md).

## Steps

1. **Copy the template** from `templates/module.nix` to `modules/<module_name>.nix`, replacing `<module_name>` with the name of your module.
2. **Edit enable option**:
   2.1. Replace `mymodule` in `options.mymodule.enable` with the actual name of your module.
   2.2. Update the `description` field of the option to provide a brief explanation of what the module provides.
3. **Implement the module**:
   3.1. See which features are available to enable by looking at `modules/features/`.
   3.2. Enable the necessary features in the `config` attribute set. It's also possible to set other Nix options directly, but it's probably better to wrap that in a feature.
4. **Remove unused flake inputs at the top of the file**.
5. **Enable the module** in the relevant host or user configuration file (e.g., `hosts/hostname/default.nix` or `users/username/default.nix`) by setting its `enable` option to `true`.
6. **Check for syntax errors** using the `nil` LSP by running `nil diagnostics <path_to_module_file>.nix`.
7. **Format the file** using `alejandra` by running `alejandra format <path_to_module_file>.nix`.
8. **Build and switch to the new configuration** by running `oss` (this is a zsh alias for `nh os switch` and `nixos-rebuild switch`). Alternatively, use the command `osb` to rebuild the configuration without switching to it, but make it the boot default.
9. If there are issues during building, check the logs for errors and fix them accordingly.
