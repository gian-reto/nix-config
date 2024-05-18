# nix-config

My NixOS configurations

## Usage

1. Clone this repository:

```sh
git clone https://github.com/gian-reto/nix-config.git ~/Code/gian-reto/nix-config
```

2. Apply the configuration (remember to replace `hostname` with the hostname of
   the machine, see `flake.nix` for available hostnames):

```sh
sudo nixos-rebuild switch --flake ~/Code/gian-reto/nix-config#hostname

# or using `nh`:

nh os switch ~/Code/gian-reto/nix-config --ask
```
