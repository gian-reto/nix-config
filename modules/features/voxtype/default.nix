{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.features.voxtype;
  voxtype = pkgs.voxtype-vulkan;
  toml = pkgs.formats.toml {};
  manifest = toml.generate "voxtype-osd.toml" {
    name = "softly";
    version = "0.1.0";
    compatibility = "voxtype quickshell style packages";
    palette = "package";
    layout = "custom";
    qml_entry = "pill.qml";
    colors = {
      background = "#12151c";
      foreground = "#e6e8ee";
      accent = "#3b82f6";
    };
    frame = {
      background = "none";
      border = "none";
      glow = false;
      halo = false;
    };
  };
  # Nixpkgs does not install Voxtype's Quickshell resources.
  frontend = pkgs.runCommand "voxtype-quickshell" {} ''
    mkdir -p "$out/quickshell" "$out/softly"
    cp -r "${voxtype.src}/quickshell/." "$out/quickshell/"
    cp "${voxtype.src}/LICENSE" "$out/quickshell/LICENSE"
    cp "${./pill.qml}" "$out/softly/pill.qml"
    cp "${manifest}" "$out/softly/voxtype-osd.toml"
  '';
in {
  options.features.voxtype.enable = lib.mkOption {
    description = "Whether to enable Voxtype voice dictation.";
    type = lib.types.bool;
    default = false;
    example = true;
  };

  config.hm = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.wl-clipboard
      pkgs.wtype
    ];

    services.voxtype = {
      enable = true;
      package = voxtype;
      loadModels = ["small.en"];
      environment = {
        PATH = lib.makeBinPath [
          pkgs.coreutils
          pkgs.quickshell
          voxtype
          pkgs.which
          pkgs.wl-clipboard
          pkgs.wtype
        ];
        RUST_LOG = "off";
        VOXTYPE_OSD_QML_PATH = "${frontend}/quickshell";
      };
      settings = {
        audio = {
          feedback = {
            enabled = false;
          };
          pause_media = true;
        };
        hotkey.enabled = false;
        osd = {
          enabled = true;
          frontend = "quickshell";
          palette = "package";
          plugin_path = "${frontend}/softly";
          style = "softly";
        };
        output = {
          append_text = " ";
          notification = {
            on_no_speech = false;
            on_recording_start = false;
            on_recording_stop = false;
            on_transcription = false;
          };
        };
        # Filter silent clips after recording without stopping on thinking pauses.
        vad = {
          backend = "energy";
          enabled = true;
        };
        whisper = {
          model = "small.en";
          language = "en";
        };
      };
    };

    # Native libraries and child processes can write outside Rust's logger.
    systemd.user.services.voxtype.Service = {
      StandardError = "null";
      StandardOutput = "null";
    };

    wayland.windowManager.hyprland.extraConfig =
      lib.mkIf (
        config.features.desktop.enable && config.features.desktop.compositor == "hyprland"
      ) (lib.mkAfter ''
        do
          -- Blur the capsule without blurring faint outlines or the transparent host.
          hl.layer_rule({
            name = "voxtype-blur",
            match = { namespace = "^voxtype-osd$" },
            blur = true,
            ignore_alpha = 0.5,
            xray = false
          })

          -- Keep existing XKB options and bind the physical Caps Lock key.
          local keyboard_options = hl.get_config("input:kb_options")
          hl.config({ input = {
            kb_options = keyboard_options == "" and "caps:none" or keyboard_options .. ",caps:none"
          } })
          hl.bind("code:66", hl.dsp.exec_cmd("${lib.getExe voxtype} record start"), {
            description = "Start voice dictation",
            repeating = false
          })
          hl.bind("code:66", hl.dsp.exec_cmd("${lib.getExe voxtype} record stop"), {
            description = "Stop voice dictation",
            release = true
          })
        end
      '');
  };
}
