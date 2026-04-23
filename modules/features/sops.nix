{
  config,
  inputs,
  lib,
  ...
}: {
  options.features.sops.enable = lib.mkOption {
    description = ''
      Whether to enable sops-nix (via SSH/GPG).
    '';
    type = lib.types.bool;
    default = false;
    example = true;
  };

  config = lib.mkIf config.features.sops.enable {
    osModules = [
      inputs.sops-nix.nixosModules.sops
    ];

    os = {
      sops = {
        age = {
          generateKey = false;
          keyFile = "/var/lib/sops-nix/key.txt";
          sshKeyPaths = lib.mkForce [];
        };
        defaultSopsFile = inputs.nix-secrets + "/secrets.yaml";
      };
    };
  };
}
