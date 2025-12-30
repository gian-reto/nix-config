# Module for enabling desktop environment / GUI features.
{
  config,
  lib,
  pkgs,
  ...
}: {
  options.gui.enable = lib.mkOption {
    description = ''
      Whether to enable a desktop environment and some GUI applications.
    '';
    type = lib.types.bool;
    default = false;
    example = true;
  };

  config = lib.mkIf config.gui.enable {
    # Enable the desktop feature.
    features.desktop.enable = true;

    # Enable related features.
    features.alacritty.enable = true;
    features.audio.enable = true;
    features.bluetooth.enable = true;
    features.chromium.enable = true;
    features.containers.enable = true;
    features.firefox.enable = true;
    features.flatpak.enable = true;
    features.ghostty.enable = true;
    # Only enabled for graphical environments because it uses (interactive)
    # smartcard prompts.
    features.git.enable = true;
    features.gpg.enable = true;
    features.gtk.enable = true;
    features.nfs.enable = true;
    features.opencode.enable = true;
    features.op.enable = true;
    features.ssh.enable = true;
    features.valent.enable = true;
    features.vpn.enable = true;
    features.vscode.enable = true;
    features.yubikey.enable = true;

    hm.home.packages = with pkgs; [
      # GNOME core applications.
      baobab # Disk usage analyzer.
      evince # Document viewer.
      file-roller # Archive manager.
      geary # Email client.
      gnome-calculator
      gnome-characters # Character map.
      gnome-disk-utility # Disk utility.
      gnome-font-viewer # Font viewer.
      gnome-logs # Log viewer.
      gnome-maps # Maps.
      gnome-text-editor
      loupe # Image viewer.
      nautilus # File manager.
      totem # Video player.

      # Additional applications.
      apostrophe # Minimal markdown editor.
      binary # Number base converter.
      collision # File hash verifier.
      curtail # Image compressor.
      d-spy # D-Bus exploration tool.
      decibels # Audio player.
      fractal # Matrix client.
      geekbench # Benchmarking tool.
      github-desktop # GitHub desktop client.
      gnome-obfuscate # Image obfuscator.
      impression # Bootable drive writer.
      metadata-cleaner # Metadata cleaner.
      obsidian # Note-taking app.
      parabolic # Video & audio downloader.
      pods # Podman desktop client.
      resources # System monitor.
      seabird # Kubernetes desktop client.
      showtime # Video player.
      snapshot # Camera app.
      warp # Magic Wormhole client.
      wildcard # Regex testing tool.
      zed-editor # Code editor.
    ];
  };
}
