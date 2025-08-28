{
  lib,
  config,
  inputs,
  ...
}: let
  secretsPath = builtins.toString inputs.nix-secrets;
in {
  options.features.sops.enable = lib.mkOption {
    description = ''
      Whether to enable sops-nix.
    '';
    type = lib.types.bool;
    default = false;
    example = true;
  };

  config.hmModules = [
    inputs.sops-nix.homeManagerModules.sops
  ];

  config.hm = lib.mkIf config.features.sops.enable {
    sops = {
      age.sshKeyPaths = lib.mkForce [];
      gnupg = {
        home = "~/.gnupg";
        sshKeyPaths = [];
      };

      secrets = {
        "example_key" = {
          format = "yaml";
          sopsFile = "${secretsPath}/secrets/example.yaml";
          path = "/home/${config.hmUsername}/example-secret";
        };
      };
    };
  };
}
