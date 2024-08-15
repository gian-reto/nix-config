{
  config,
  lib,
  ...
}: {
  options.features.direnv.enable = lib.mkOption {
    description = ''
      Whether to enable `direnv`.
    '';
    type = lib.types.bool;
    default = false;
    example = true;
  };

  config.hm = lib.mkIf config.features.direnv.enable {
    programs = {
      direnv = {
        enable = true;

        nix-direnv = {
          enable = true;
        };

        stdlib = ''
          use_oprc() {
            # From: https://github.com/venkytv/direnv-op/blob/main/oprc.sh.
            [[ -f .oprc ]] || return 0
            direnv_load op run --env-file .oprc --no-masking -- direnv dump
          }

          watch_file .oprc
        '';
        enableZshIntegration = true;
      };
    };
  };
}
