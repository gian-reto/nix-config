{
  imports = [
    # Features.
    ./features/alacritty.nix
    ./features/android.nix
    ./features/audio.nix
    ./features/bash.nix
    ./features/bat.nix
    ./features/bluetooth.nix
    ./features/btop.nix
    ./features/chromium.nix
    ./features/containers.nix
    ./features/desktop
    ./features/direnv.nix
    ./features/distributed-builds.nix
    ./features/fastfetch.nix
    ./features/firefox.nix
    ./features/flatpak.nix
    ./features/ghostty.nix
    ./features/git.nix
    ./features/gpg.nix
    ./features/gtk.nix
    ./features/i18n.nix
    ./features/network.nix
    ./features/nfs.nix
    ./features/ollama.nix
    ./features/opencode
    ./features/op.nix
    ./features/ssh.nix
    ./features/steam.nix
    ./features/valent.nix
    ./features/virtualization.nix
    ./features/vpn.nix
    ./features/vscode.nix
    ./features/xdg.nix
    ./features/yubikey.nix
    ./features/zsh.nix

    # Modules.
    ./common.nix
    ./gui.nix
    ./laptop.nix
    ./phone.nix
    ./server.nix
  ];
}
