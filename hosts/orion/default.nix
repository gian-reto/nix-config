{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: {
  # Import hardware-specific configuration for Fairphone 5 and GNOME Mobile.
  osModules = [
    inputs.nixos-fairphone-fp5.nixosModules.gnome-mobile
  ];

  # Enable my modules!
  phone.enable = true;

  # Enable individual features.
  features.distributed-builds.enable = true;

  # Machine-specific configuration.
  os = {
    nixos-fairphone-fp5.hardware.serial.enable = true;

    networking.hostName = "orion";

    nixpkgs.config = {
      allowUnfree = true;
      allowUnfreePredicate = _: true;
      # FIXME: This is needed because of `chatty`, which supports Matrix and therefore
      # unfortunately includes a dependency on `olm`, which is currently marked as
      # insecure. This should be removed or fixed ASAP.
      permittedInsecurePackages = [
        "olm-3.2.16"
      ];
    };

    # Set `initialPassword`, because it's easy to start with...
    users.users."${config.hmUsername}" = {
      initialPassword = "nixos";
    };

    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "prohibit-password";
      };
    };

    users.users.root = {
      openssh.authorizedKeys.keys = lib.splitString "\n" (builtins.readFile ../../files/ssh.pub);
    };

    networking.firewall = {
      enable = true;
      allowedTCPPorts = [
        22 # SSH access.
      ];

      # Disable logging since mobile kernel lacks xt_LOG module.
      logRefusedConnections = false;
      logRefusedPackets = false;
      logReversePathDrops = false;
      logRefusedUnicastsOnly = false;
    };

    # Disable documentation (hides desktop icon).
    documentation.nixos.enable = false;

    environment.sessionVariables = {
      # Electron apps should use Wayland.
      NIXOS_OZONE_WL = "1";
    };

    # Core GNOME apps are set by the `gnome-mobile` module. The additional packages
    # listed here can be seen as an example of other useful apps for mobile use.
    environment.systemPackages = with pkgs; [
      # Miscellaneous packages.
      wl-clipboard # Wayland clipboard util, also used for Waydroid clipboard sharing.

      # Apps.
      dialect # Translation app.
      firefox-mobile
      gnome-decoder # QR code scanner & generator.
      gnome-software
      newsflash # RSS reader.
      resources # System resource monitor.
      warp # Magic wormhole file transfer.

      # GNOME extensions.
      gnomeExtensions.app-hider # Hide desktop icons.
    ];

    # Enable Waydroid.
    virtualisation.waydroid.enable = true;

    system.stateVersion = "25.05";
  };

  hm.home.stateVersion = "25.05";
}
