{
  imports = [
    # Features.
    ./features/ags.nix
    ./features/alacritty.nix
    ./features/audio.nix
    ./features/bash.nix
    ./features/bat.nix
    ./features/bluetooth.nix
    ./features/btop.nix
    ./features/containers.nix
    ./features/cursor.nix
    ./features/fastfetch.nix
    ./features/firefox.nix
    ./features/fonts.nix
    ./features/git.nix
    ./features/gpg.nix
    ./features/greeter.nix
    ./features/gtk.nix
    ./features/hyprland.nix
    ./features/hyprlock.nix
    ./features/i18n.nix
    ./features/network.nix
    ./features/security.nix
    ./features/ssh.nix
    ./features/tlp.nix
    ./features/valent.nix
    ./features/vscode.nix
    ./features/xdg.nix
    ./features/yubikey.nix
    ./features/zsh.nix

    # Modules.
    ./common.nix
    ./gui.nix
    ./laptop.nix
  ];
}
