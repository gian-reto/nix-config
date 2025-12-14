{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}: {
  options.features.ollama.enable = lib.mkOption {
    description = ''
      Whether to enable ollama.
    '';
    type = lib.types.bool;
    default = false;
    example = true;
  };

  config.os = lib.mkIf config.features.ollama.enable {
    services.ollama = {
      enable = true;

      package = lib.mkIf (osConfig.networking.hostName == "atlas") pkgs.ollama-rocm;
      port = 11434; # Default port.
      rocmOverrideGfx = lib.mkIf (osConfig.networking.hostName == "atlas") "10.3.0";
    };
  };
}
