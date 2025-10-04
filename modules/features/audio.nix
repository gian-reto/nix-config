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
    services.pulseaudio.enable = lib.mkForce false;

    # Enable Avahi for mDNS/zeroconf service discovery (required for AirPlay).
    services.avahi.enable = true;

    # Enable `pipewire` stack.
    services.pipewire = {
      enable = true;

      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      wireplumber.enable = true;

      # Open firewall for AirPlay (RAOP) connections (UDP ports 6001-6002).
      raopOpenFirewall = true;

      # AirPlay (RAOP) support.
      configPackages = [
        (pkgs.writeTextDir "share/pipewire/pipewire.conf.d/10-raop-discover.conf" ''
          context.modules = [{
            name = libpipewire-module-zeroconf-discover
            args = {}
          }
          {
            name = libpipewire-module-raop-discover
            args = {
              roap.discover-local = false
              raop.latency.ms = 248.16
              stream.rules = [
                {
                  matches = [
                    {
                    raop.ip = "~.*"
                    }
                  ]
                  actions = {
                    create-stream = {
                      stream.props = {
                        media.class = "Audio/Sink"
                        sess.latency.msec = 248.16
                      }
                    }
                  }
                }
              ]
            }
          }]
        '')
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
