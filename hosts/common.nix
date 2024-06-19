{
  pkgs,
  ...
}: {
  imports = [
    ./nix.nix
  ];

  config.os = {
    hardware.enableRedistributableFirmware = true;

    programs = {
      dconf.enable = true;
      nix-ld.enable = true;
    };

    networking.domain = "hosts.internal.giantarnutzer.com";
  };

  config.hm = {
    home = {
      sessionPath = [
        "$HOME/.local/bin"
      ];

      sessionVariables = {
        NIXPKGS_ALLOW_UNFREE = "1";
        NIXPKGS_ALLOW_INSECURE = "1";
        # Default flake path for `nh` (https://github.com/viperML/nh).
        FLAKE = "$HOME/Code/gian-reto/nix-config";
      };

      packages = with pkgs; [
        comma # Runs programs without installing them. Example: `, cowsay howdy`.

        httpie # Better curl.

        nil # Nix LSP.
        alejandra # Nix formatter.
        nh # Nice wrapper for NixOS and `home-manager`.
      ];
    };
  };
}