{pkgs, ...}: {
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

        age # Modern encryption tool.
        devbox # Simple nix powered development environments.
        httpie # Better curl.
        jq # JSON processor.
        nix-index
        openssl
        pv # Pipe progress monitor.
        python3
        sops # Secrets management.

        alejandra # Nix formatter.
        nil # Nix LSP.
        nh # Nice wrapper for NixOS and `home-manager`.
      ];
    };
  };
}
