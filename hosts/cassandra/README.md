# First-install instructions for `cassandra` (Lenovo ThinkPad X13s)

Installation guide for `cassandra`. This device uses a Qualcomm Snapdragon 8cx Gen 3 SoC (SC8280XP) and cannot be installed using `nixos-anywhere`, because `kexec` does not work on this hardware. Instead, boot the live ISO from [gian-reto/x13s-nixos](https://github.com/gian-reto/x13s-nixos), then install this flake from the live environment.

## 1. Build and boot the X13s live ISO

Follow the build and flashing instructions in `gian-reto/x13s-nixos`. Once the ISO is flashed, boot the X13s from it and open a shell on the device.

## 2. Connect to the internet

The live ISO does not include a graphical environment, so you will need to connect to Wi-Fi from the command line. The easiest way to do this is using `nmtui` or `nmcli`.

## 3. Write the LUKS encryption key to the live system

Copy the LUKS key to the device at `/tmp/secret.key`. Then, set the correct permissions using:

```sh
chmod 600 /tmp/secret.key
```

## 4. Clone this repository on the live system

```sh
mkdir -p ~/Code/gian-reto
git clone https://github.com/gian-reto/nix-config.git ~/Code/gian-reto/nix-config
cd ~/Code/gian-reto/nix-config
```

## 5. Partition and mount the disk with `disko`

Run `disko` from the live system via `nix run` to partition, format, encrypt, and mount the target disk:

```sh
sudo nix run github:nix-community/disko -- \
  --mode destroy,format,mount \
  --flake ~/Code/gian-reto/nix-config#cassandra
```

Because `hosts/cassandra/disk-configuration.nix` uses `passwordFile = "/tmp/secret.key";`, `disko` will read the key from `/tmp/secret.key` on the live system while provisioning the disk. When it finishes, the passphrase you provided via `secret.key` will be the LUKS unlock key for the encrypted partition.

## 6. Install NixOS

After `disko` has mounted the target filesystem at `/mnt`, install the system.

Because this flake currently contains the private `nix-services` input, create a temporary local stub flake so `nixos-install` does not try to fetch it over SSH from the live environment:

```sh
mkdir -p /tmp/nix-services-stub
cat > /tmp/nix-services-stub/flake.nix <<'EOF'
{
  outputs = { ... }: {
    nixosModules.default = { ... }: {};
  };
}
EOF

sudo nixos-install \
  --max-jobs 1 \
  --override-input nix-services path:/tmp/nix-services-stub \
  --flake ~/Code/gian-reto/nix-config#cassandra
```

Note: `--max-jobs 1` is used because `nixos-install` might otherwise be OOM killed when building directly on the device.

## 7. Set the password for `gian`

Before rebooting, enter the installed system and set a password for `gian`:

```sh
sudo nixos-enter --root /mnt -c 'passwd gian'
```

## 8. Reboot

```sh
reboot
```

Remove the USB drive when the device powers off. The X13s will boot into the freshly installed NixOS system and prompt for the LUKS passphrase.
