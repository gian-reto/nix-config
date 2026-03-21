# First-install instructions for `cassandra` (Lenovo ThinkPad X13s)

Installation guide for `cassandra`. This device uses a Qualcomm SC8280XP chip
(aarch64-linux) and cannot be installed using `nixos-anywhere`, because `kexec`
does not work on this hardware. Instead, install from a custom USB disk image
built from this repository.

## 1. Build the installer image

Run the following from the root of this repository on your controller machine:

```sh
nix build .#packages.aarch64-linux.cassandra-installer-image \
  --max-jobs 0 \
  --builders "ssh://eu.nixbuild.net aarch64-linux - 100 1 big-parallel,benchmark" \
  --option builders-use-substitutes true
```

The resulting disk image is at `result/cassandra-installer.raw`.

## 2. Flash the image to a USB drive

Replace `/dev/sdX` with the actual device path of your USB drive.

```sh
dd if=result/cassandra-installer.raw of=/dev/sdX bs=4M status=progress
sync
```

## 3. Boot the X13s from USB

1. Power on the X13s and press `Enter`, then `F12` to open the boot menu.
2. Select the USB drive.
3. Wait for the system to boot and for `sshd` to start.

## 4. Connect over SSH

The system accepts connections as `root` using the key from `files/ssh.pub`.

```sh
ssh root@cassandra-installer
```

## 5. Write the LUKS encryption key to the live system

Run the following on your controller machine to write the LUKS key to the live
system's `/tmp/secret.key`:

```sh
op read op://Development/3x3x7fbtnr74l65fjtakpznuui/password \
  | ssh root@cassandra-installer "cat > /tmp/secret.key"
```

## 6. Clone the repository on the live system

```sh
ssh root@cassandra-installer

mkdir -p ~/Code/gian-reto
git clone https://github.com/gian-reto/nix-config.git ~/Code/gian-reto/nix-config
```

## 7. Run `disko-install`

`disko-install` partitions, formats, encrypts, and installs NixOS in one step.
Run it on the live system:

```sh
disko-install \
  --flake ~/Code/gian-reto/nix-config#cassandra \
  --disk main /dev/nvme0n1 \
  --disk-encryption-keys /tmp/secret.key /tmp/secret.key
```

When it finishes, the passphrase you provided via `secret.key` will be the LUKS
unlock key for the encrypted partition.

## 8. Reboot

```sh
reboot
```

Remove the USB drive when the device powers off. The X13s will boot into the
freshly installed NixOS system and prompt for the LUKS passphrase.
