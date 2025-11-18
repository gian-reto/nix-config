{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    ./nix.nix
  ];

  config.osModules = [
    inputs.nix-index-database.nixosModules.nix-index
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
        NH_FLAKE = "$HOME/Code/gian-reto/nix-config";
      };

      packages = with pkgs; [
        comma # Runs programs without installing them. Example: `, cowsay howdy`.
        curl

        age # Modern encryption tool.
        devbox # Simple nix powered development environments.
        httpie # Better curl.
        jq # JSON processor.
        openssl
        pv # Pipe progress monitor.
        python3
        ripgrep
        shellcheck
        sops # Secrets management.
        tree

        alejandra # Nix formatter.
        nh # Nice wrapper for NixOS and `home-manager`.
        nil # Nix LSP.
        nurl # Nix fetcher call generator.
      ];
    };
  };
}
