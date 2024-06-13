# ❄️ My NixOS Configuration

[![built with nix](https://img.shields.io/static/v1?logo=nixos&logoColor=white&label=&message=Built%20with%20Nix&color=7e7eff)](https://builtwithnix.org)
![state: experimental](https://img.shields.io/badge/state-experimental-orange)
![flakes: crunchy](https://img.shields.io/badge/flakes-crunchy-yellow)

NixOS and `home-manager` configurations for my personal machines.

## Structure

I'm trying to keep the config as simple as possible. I don't want any crazy overlays or helpers and stuff (if possible; let's see how that goes) ─ I just want to toggle features on and off, depending on the respective host or user.

The smallest building blocks of my configuration are contained in `features` (e.g., support for audio). Each feature should be as self-contained as possible, and should be able to be enabled or disabled independently of the others. Features are then grouped into `modules`, which cover entire use-cases (e.g., a graphical desktop environment) a user or host might have. `users` and `hosts` may then enable these modules to build a complete configuration.

I'm using [combined-manager](https://github.com/FlafyDev/combined-manager) to colocate `home-manager` and NixOS configurations that belong to the same feature in the same file.

```plaintext
hosts/
└── abc/
    └── ...
modules/
└── features/
    └── ...
pkgs/
└── ...
users/
└── abc/
    └── ...
flake.lock
flake.nix
...
```

`modules` may expose various settings, which need to be provided by the consumer when enabling a specific module.

`features` only expose a single setting, which is a boolean value indicating whether the feature should be enabled or not. However, these switches are controlled by the `modules` that import them, so there is no need to enable them manually when enabling `modules` for a user or host.

Lastly, `pkgs` contains custom packages that are not available in the official Nixpkgs repository.

## Usage

1. Clone this repository:

```sh
git clone https://github.com/gian-reto/nix-config.git ~/Code/gian-reto/nix-config
```

2. Apply the configuration (remember to replace `hostname` with the hostname of the machine, see `flake.nix` for available hostnames):

```sh
sudo nixos-rebuild switch --flake ~/Code/gian-reto/nix-config#hostname

# or using `nh`:

nh os switch ~/Code/gian-reto/nix-config#hostname
```

## Thanks

My config has been inspired by the many great configurations out there. Some of the most notable ones are:

- [n3oney/nixus](https://github.com/n3oney/nixus).
- [linuxmobile/kaku](https://github.com/linuxmobile/kaku).
- [fufexan/dotfiles](https://github.com/fufexan/dotfiles).
- [Aylur/dotfiles](https://github.com/Aylur/dotfiles).
- [Misterio77/nix-config](https://github.com/Misterio77/nix-config).

...and special thanks to the maintainers of the amazing projects used in this configuration!
