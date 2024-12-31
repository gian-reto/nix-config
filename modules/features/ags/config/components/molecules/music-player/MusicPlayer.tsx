import { Variable, bind, derive } from "astal";

import { BoxProps } from "astal/gtk4/widget";
import { Gtk } from "astal/gtk4";
import Mpris from "gi://AstalMpris";
import Pango from "gi://Pango?version=1.0";
import { cx } from "../../../util/cx";

const mpris = Mpris.get_default();

type MusicPlayerProps = Omit<BoxProps, "cssClasses"> & {
  readonly cssClasses?: string[];
};

export const MusicPlayer = (props: MusicPlayerProps) => {
  const { cssClasses, ...restProps } = props;

  const currentPlayerState = Variable<Mpris.Player | undefined>(undefined);

  const onPlayersChanged = () => {
    const player =
      mpris
        .get_players()
        .find(
          (player) => player.playbackStatus === Mpris.PlaybackStatus.PLAYING
        ) ??
      mpris
        .get_players()
        .find(
          (player) => player.playbackStatus === Mpris.PlaybackStatus.PAUSED
        );

    if (player) {
      currentPlayerState.set(player);
    } else {
      currentPlayerState.set(undefined);
    }
  };

  // Initially set the player state.
  onPlayersChanged();

  // Subscribe to player changes.
  mpris.connect("player-added", onPlayersChanged);
  mpris.connect("player-closed", onPlayersChanged);

  return (
    <box
      {...restProps}
      cssClasses={cx(
        cssClasses,
        "bg-gray-400",
        "duration-100",
        "p-3",
        "pr-5",
        "rounded-xl",
        "shadow-sm",
        "space-x-3"
      )}
      baselinePosition={Gtk.BaselinePosition.CENTER}
      hexpand={false}
      vexpand={false}
      visible={bind(currentPlayerState).as((player) =>
        player ? bind(player, "available") : false
      )}
    >
      {bind(currentPlayerState).as((player) =>
        player ? (
          <>
            <box
              halign={Gtk.Align.START}
              hexpand={false}
              valign={Gtk.Align.CENTER}
              vexpand={false}
            >
              {bind(player, "coverArt").as((coverArt) =>
                !!coverArt ? (
                  <image
                    cssClasses={[
                      "min-w-14",
                      "min-h-14",
                      "rounded-lg",
                      "shadow-sm",
                    ]}
                    file={coverArt}
                    overflow={Gtk.Overflow.HIDDEN}
                  />
                ) : (
                  <box
                    cssClasses={[
                      "bg-gray-500",
                      "min-w-14",
                      "min-h-14",
                      "rounded-lg",
                    ]}
                  />
                )
              )}
            </box>
            <box
              cssClasses={["space-y-0.5"]}
              halign={Gtk.Align.START}
              hexpand
              valign={Gtk.Align.CENTER}
              vexpand={false}
              vertical
            >
              <label
                cssClasses={["font-semibold", "text-white"]}
                ellipsize={Pango.EllipsizeMode.END}
                halign={Gtk.Align.START}
                justify={Gtk.Justification.LEFT}
                lines={1}
                maxWidthChars={14}
                valign={Gtk.Align.CENTER}
                vexpand={false}
              >
                {bind(player, "title")}
              </label>
              <label
                cssClasses={["text-md", "text-gray-50"]}
                ellipsize={Pango.EllipsizeMode.END}
                halign={Gtk.Align.START}
                justify={Gtk.Justification.LEFT}
                lines={1}
                maxWidthChars={14}
                valign={Gtk.Align.CENTER}
                vexpand={false}
              >
                {bind(player, "artist")}
              </label>
            </box>
            <box
              cssClasses={["space-x-2"]}
              halign={Gtk.Align.END}
              hexpand={false}
              valign={Gtk.Align.CENTER}
              vexpand={false}
            >
              <button
                cssClasses={[
                  "bg-transparent",
                  "min-h-6",
                  "min-w-6",
                  "p-1.5",
                  "rounded-full",
                  "disabled:text-gray-100",
                  "hover:bg-gray-300",
                ]}
                halign={Gtk.Align.START}
                hexpand={false}
                valign={Gtk.Align.CENTER}
                vexpand={false}
                sensitive={bind(player, "canGoPrevious")}
                onClicked={() => player.previous()}
              >
                <image iconName="media-skip-backward-symbolic" />
              </button>
              {bind(
                derive([
                  bind(player, "canPlay"),
                  bind(player, "canPause"),
                  bind(player, "playbackStatus"),
                ])
              ).as(([canPlay, canPause, playbackStatus]) => (
                <button
                  cssClasses={[
                    "bg-transparent",
                    "min-h-6",
                    "min-w-6",
                    "p-1.5",
                    "rounded-full",
                    "disabled:text-gray-100",
                    "hover:bg-gray-300",
                  ]}
                  halign={Gtk.Align.START}
                  hexpand={false}
                  valign={Gtk.Align.CENTER}
                  vexpand={false}
                  sensitive={canPlay || canPause}
                  onClicked={() => player.play_pause()}
                >
                  <image
                    iconName={
                      playbackStatus === Mpris.PlaybackStatus.PLAYING
                        ? "media-playback-pause-symbolic"
                        : "media-playback-start-symbolic"
                    }
                  />
                </button>
              ))}
              <button
                cssClasses={[
                  "bg-transparent",
                  "min-h-6",
                  "min-w-6",
                  "p-1.5",
                  "rounded-full",
                  "disabled:text-gray-100",
                  "hover:bg-gray-300",
                ]}
                halign={Gtk.Align.START}
                hexpand={false}
                valign={Gtk.Align.CENTER}
                vexpand={false}
                sensitive={bind(player, "canGoNext")}
                onClicked={() => player.next()}
              >
                <image iconName="media-skip-forward-symbolic" />
              </button>
            </box>
          </>
        ) : (
          <></>
        )
      )}
    </box>
  );
};
