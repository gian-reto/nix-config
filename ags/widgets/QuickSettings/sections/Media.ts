import { type MprisPlayer } from "types/service/mpris";
import { icons } from "lib/icons";
import { clamp } from "lib/utils";

const mpris = await Service.import("mpris");

export const Media = () => {
  const widget = Widget.Box({
    vertical: true,
    hpack: "fill",
    hexpand: true,
    class_name: "media vertical",
  });

  const onPlayersChanged = () => {
    const player =
      mpris.players.find((p) => p.play_back_status === "Playing") ??
      mpris.players.find((p) => p.play_back_status === "Paused") ??
      mpris.players[0];

    if (player) {
      widget.child = Player(player);
    } else {
      widget.child?.destroy();
    }
  };

  return widget
    .hook(mpris, onPlayersChanged, "player-closed")
    .hook(mpris, onPlayersChanged, "player-added");
};

const Player = (player: MprisPlayer) => {
  const cover = Widget.Box({
    class_name: "cover",
    vpack: "start",
    hpack: "start",
    hexpand: true,
    css: Utils.merge(
      [player.bind("cover_path"), player.bind("track_cover_url")],
      (path, url) => `
            min-width: 128px;
            min-height: 128px;
            background-image: url('${path || url}');
        `
    ),
  });

  const title = Widget.Label({
    class_name: "title",
    max_width_chars: 20,
    truncate: "end",
    hpack: "start",
    label: player.bind("track_title"),
  });

  const artist = Widget.Label({
    class_name: "artist",
    max_width_chars: 20,
    truncate: "end",
    hpack: "start",
    label: player.bind("track_artists").as((a) => a.join(", ")),
  });

  const positionSlider = Widget.Slider({
    class_name: "slider",
    draw_value: false,
    on_change: ({ value }) => (player.position = value * player.length),
    setup: (self) => {
      const update = () => {
        const { length, position } = player;

        self.value = length > 0 ? position / length : 0;
      };

      self.hook(player, update);
      self.hook(player, update, "position");
      self.poll(1000, update);
    },
  });

  const positionLabel = Widget.Label({
    class_name: "position",
    hpack: "start",
    setup: (self) => {
      const update = (_: unknown, time?: number) => {
        self.label = getFormattedLength(time || player.position);
      };

      self.hook(player, update, "position");
      self.poll(1000, update);
    },
  });

  const lengthLabel = Widget.Label({
    class_name: "length",
    hpack: "end",
    label: player.bind("length").as(getFormattedLength),
  });

  const playPause = Widget.Button({
    class_name: "play-pause",
    on_clicked: () => player.playPause(),
    sensitive: player.bind("can_play"),
    child: Widget.Icon({
      icon: player.bind("play_back_status").as((s) => {
        switch (s) {
          case "Playing":
            return icons.mpris.playing;
          case "Paused":
          case "Stopped":
            return icons.mpris.stopped;
          default:
            return icons.mpris.stopped;
        }
      }),
    }),
  });

  const prev = Widget.Button({
    on_clicked: () => player.previous(),
    sensitive: player.bind("can_go_prev"),
    child: Widget.Icon(icons.mpris.prev),
  });

  const next = Widget.Button({
    on_clicked: () => player.next(),
    sensitive: player.bind("can_go_next"),
    child: Widget.Icon(icons.mpris.next),
  });

  return Widget.Box(
    { class_name: "player", vexpand: false },
    cover,
    Widget.Box(
      {
        class_name: "metadata",
        vertical: true,
        hpack: "fill",
        hexpand: true,
      },
      Widget.Box([title]),
      artist,
      Widget.Box({ vexpand: true }),
      positionSlider,
      Widget.CenterBox({
        class_name: "footer horizontal",
        start_widget: positionLabel,
        center_widget: Widget.Box([prev, playPause, next]),
        end_widget: lengthLabel,
      })
    )
  );
};

const getFormattedLength = (length: number, digitsPerComponent: number = 2) => {
  const clampedLength = clamp(length, 0, Number.MAX_SAFE_INTEGER);

  const min = `${Math.floor(clampedLength / 60)}`.padStart(
    digitsPerComponent,
    "0"
  );
  const sec = `${Math.floor(clampedLength % 60)}`.padStart(
    digitsPerComponent,
    "0"
  );

  return `${min}:${sec}`;
};
