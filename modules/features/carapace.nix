{
  config,
  lib,
  ...
}: {
  options.features.carapace.enable = lib.mkOption {
    description = ''
      Whether to enable `carapace`.
    '';
    type = lib.types.bool;
    default = false;
    example = true;
  };

  config.hm = lib.mkIf config.features.carapace.enable {
    programs = {
      carapace = {
        enable = true;

        enableBashIntegration = config.features.bash.enable;
        enableFishIntegration = false;
        enableNushellIntegration = config.features.nushell.enable;
        enableZshIntegration = config.features.zsh.enable;
        ignoreCase = true;
      };

      zsh.initContent = lib.mkIf config.features.zsh.enable ''
        zstyle ':completion:*' format $'\e[2;37mCompleting %d\e[m'
      '';
    };
  };
}
