{
  config,
  lib,
  pkgs,
  ...
}: {
  options.features.audio.enable = lib.mkOption {
    description = ''
      Whether to enable the audio feature.
    '';
    type = lib.types.bool;
    default = false;
    example = true;
  };

  config.os = lib.mkIf config.features.audio.enable {
    security.rtkit.enable = true;

    # Disable `pulseaudio`.
    hardware.pulseaudio.enable = false;

    # Probably needed for AirPlay support.
    services.avahi.enable = true;

    # Enable `pipewire` stack.
    services.pipewire = {
      enable = true;
      package = pkgs.pipewire.override {
        raopSupport = true;
      };

      alsa.enable = true;
      alsa.support32Bit = true;
      jack.enable = true;
      pulse.enable = true;
      wireplumber.enable = true;

      # AirPlay support.
      raopOpenFirewall = true;
      configPackages = [
        (pkgs.writeTextFile {
          name = "pipewire-airplay";
          text = builtins.toJSON {
            "context.modules" = [
              {
                name = "libpipewire-module-zeroconf-discover";
                args = {};
              }
              {
                name = "libpipewire-module-raop-discover";
                args = {};
              }
            ];
          };
          destination = "/share/pipewire/pipewire.conf.d/airplay.conf";
        })
      ];
    };

    security.pam.loginLimits = [
      {
        domain = "@audio";
        item = "memlock";
        type = "-";
        value = "unlimited";
      }
      {
        domain = "@audio";
        item = "rtprio";
        type = "-";
        value = "99";
      }
      {
        domain = "@audio";
        item = "nofile";
        type = "soft";
        value = "99999";
      }
      {
        domain = "@audio";
        item = "nofile";
        type = "hard";
        value = "524288";
      }
    ];
  };

  config.hm = lib.mkIf (config.features.audio.enable && config.gui.enable) {
    home.packages = with pkgs; [
      pavucontrol
      playerctl
    ];

    services.playerctld = {
      enable = true;
    };
  };
}
