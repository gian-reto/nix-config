# Overview: Feature

This guide provides an overview of the concept of a "feature" in this NixOS configuration. For information on how to add a new feature, see the [feature addition recipe](./feature_add_recipe.md).

The term "feature" is not a concept of NixOS itself, but rather a term used in this repository to refer to a self-contained configuration that can be enabled or disabled independently of others.

## Introduction

This repository uses [combined-manager](https://github.com/FlafyDev/combined-manager), which allows using `home-manager` and `os` configuration objects in the same file. This makes it easy to set all the necessary options for a feature in a single place.

As an example, the following list highlights some of the features contained in this configuration, and what they do:

- `modules/features/audio.nix`: Contains the configuration for audio support with PipeWire, enables AirPlay support, and other audio-related features. Also defines some packages (including GUI applications) that are related to audio.
- `modules/features/firefox.nix`: Adds Firefox, and contains the configuration for the default Firefox profile, which includes various extensions and settings. Additionally, configures a custom theme for Firefox.
- `modules/features.zsh.nix`: Contains the configuration for `zsh`, including plugins, etc. Also contains many custom aliases or functions that are useful for daily use.

...and many more, see the `modules/features` directory for a complete list.

All features are defined in separate files in `modules/features`, and imported in `modules/default.nix`. Each feature file should contain an `enable` option in the `options.features` attribute set, e.g. `options.features.myfeature.enable`. In `modules/common.nix`, all features that should be enabled on all hosts are set to `true`, e.g. `config.features.myfeature.enable = true;`.

There are additional modules that are only used by selected hosts which enable or disable certain features, such as:

- `modules/gui.nix`: Enables features that are only relevant for graphical desktop environments, such as `hyprland`, `firefox`, etc.

Features might also be enabled directly in the configuration of a single host or user, e.g. in `hosts/<hostname>/default.nix` or `users/gian/default.nix`.

## Anatomy of a Feature

When adding a `.nix` file for a new feature, it should follow a specific structure to ensure consistency. `combined-manager` allows modules to add inputs, overlays and Home Manager and Nixpkgs options as if they are simple options. Therefore, a feature has access to `osConfig` and `hmConfig` to read the NixOS or `home-manager` config, but can also set options for both of them using `config.os = { ... }` and `config.hm = { ... }`, respectively.

The following shows the basic structure of a feature as a template. Note: Not all inputs or options are required, and are only shown here for completeness. Some features may only set NixOS options, while others may only set `home-manager` options, or both.

```nix
{
  # The usual inputs for a Nix module:
  lib,
  pkgs,
  config,
  inputs,
  # `osConfig`: Allows reading the evaluated NixOS configuration.
  osConfig,
  # `hmConfig`: Allows reading the evaluated Home Manager configuration.
  hmConfig,
  # `combinedManager`: Path to the root of `combinedManager`. Rarely used.
  combinedManager,
  # `configs`: The results of all NixOS/CombinedManager configs. Rarely used.
  configs,
  ...
}: {
  # Paths to other `.nix` modules to import. Rarely used.
  imports = [];

  # Options exposed by this feature. Important: Each feature should expose
  # exactly one option on the `features` attribute set, which is a boolean
  # value indicating whether the feature should be enabled or not, and
  # defaults to `false`. Example for a feature in
  # `modules/features/myfeature.nix`:
  options.features.myfeature.enable = lib.mkOption {
    description = ''
      Whether to enable myfeature.
    '';
    type = lib.types.bool;
    default = false;
    example = true;
  };

  config = {
    # Adds additional flake inputs. Rarely used, because inputs should be
    # added to the `flake.nix` file at the root of the repository.
    inputs = {
      name.url = "...";

      # As an example, adding `impermanance`:
      inputs.impermanence.url = "github:nix-community/impermanence";
    };

    # Importing system modules. Rarely used.
    osModules = [
      # As an example, importing the `impermanence` NixOS module:
      inputs.impermanence.nixosModules.impermanence
    ];

    # Importing Home Manager modules. Rarely used.
    hmModules = [
      # As an example, importing the `impermanence` Home Manager module:
      inputs.impermanence.nixosModules.home-manager.impermanence
    ];

    # Setting overlays. Rarely used.
    os.nixpkgs.overlays = [];

    # Using `os` to set Nixpkgs options. Commonly used.
    os = {};

    # Using `hm` to set Home Manager options. Commonly used.
    hm = {};
  };
}
```

## Tricks

Some helpful tricks for Nix code in a feature:

- The system's main user name is in `config.hmUsername`, which is useful when it has to be interpolated in a string.
- Use `lib.getExe` or `lib.getExe'` to get the path to an executable in the Nix store, e.g.:

```nix
getExe' pkgs.hello "hello" # "/nix/store/g124820p9hlv4lj8qplzxw1c44dxaw1k-hello-2.12/bin/hello"
getExe' pkgs.imagemagick "convert" # "/nix/store/5rs48jamq7k6sal98ymj9l4k2bnwq515-imagemagick-7.1.1-15/bin/convert"
```

- Sometimes, parts of the configuration in a feature should only be enabled if another feature is enabled. This can be done using the usual Nix helpers like `lib.mkIf` or `lib.optionals`. For example, the `hyprland` feature only applies the custom cursor theme if `config.features.cursor.enable` (the option exposed by the `cursor` feature) is set to `true`.
