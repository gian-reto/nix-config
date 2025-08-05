# Overview: Module

This guide provides an overview of the concept of a "module" in this NixOS configuration. For information on how to add a new module, see the [module addition recipe](./module_add_recipe.md).

Important: Most of the time, adding a new module is not necessary. Prefer adding features to the existing modules:

- `modules/common.nix`: Contains features that are enabled for all hosts. This mostly contains CLI-only features that are useful on servers, laptops, or desktops alike.
- `modules/gui.nix`: Contains features that are only relevant in graphical desktop environments.

## Anatomy of a Module

Look at the existing modules mentioned above to see how they are structured. For the most part, a module is pretty simple, and only sets the `enable` option for the relevant features to `true`.
