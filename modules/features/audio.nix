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

      # AirPlay (RAOP) support. See: https://fenguoerbian.github.io/blog/2025-10-07-airplay-in-linux.
      configPackages = [
        (pkgs.writeTextDir "share/pipewire/pipewire.conf.d/10-raop-discover.conf" ''
          context.modules = [
          {   name = libpipewire-module-raop-discover
              args = {
                  #roap.discover-local = false;
                  #raop.latency.ms = 1000
                  stream.rules = [
                      {   matches = [
                              {    raop.ip = "~.*"
                                  #raop.port = 1000
                                  #raop.name = ""
                                  #raop.hostname = ""
                                  #raop.domain = ""
                                  #raop.device = ""
                                  #raop.transport = "udp" | "tcp"
                                  #raop.encryption.type = "none" | "RSA" | "auth_setup" | "fp_sap25"
                                  #raop.audio.codec = "PCM" | "ALAC" | "AAC" | "AAC-ELD"
                                  #audio.channels = 2
                                  #audio.format = "S16" | "S24" | "S32"
                                  #audio.rate = 44100
                                  #device.model = ""
                              }
                          ]
                          actions = {
                              create-stream = {
                                  #raop.password = ""
                                  stream.props = {
                                      #target.object = ""
                                      #media.class = "Audio/Sink"
                                  }
                              }
                          }
                      }
                  ]
              }
          }
          ]
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
