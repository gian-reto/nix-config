import { assetPaths } from "assets";

export const icons = {
  audio: {
    mic: {
      high: "microphone-sensitivity-high-symbolic",
      muted: "microphone-sensitivity-muted-symbolic",
    },
  },
  bluetooth: {
    disabled: "bluetooth-disabled-symbolic",
    enabled: "bluetooth-active-symbolic",
  },
  fallback: {
    executable: "application-x-executable",
  },
  missing: "image-missing-symbolic",
  mpris: {
    next: "media-skip-forward-symbolic",
    paused: "media-playback-start-symbolic",
    playing: "media-playback-pause-symbolic",
    prev: "media-skip-backward-symbolic",
    stopped: "media-playback-start-symbolic",
  },
  notifications: {
    silent: "notifications-disabled-symbolic",
    noisy: assetPaths.icons["org.gnome.Settings-notifications-symbolic"],
  },
  powermenu: {
    logout: "system-log-out-symbolic",
    reboot: "system-reboot-symbolic",
    shutdown: "system-shutdown-symbolic",
    sleep: "weather-clear-night-symbolic",
  },
  ui: {
    arrow: {
      right: "pan-end-symbolic",
      left: "pan-start-symbolic",
      down: "pan-down-symbolic",
      up: "pan-up-symbolic",
    },
    close: "window-close-symbolic",
    lock: "system-lock-screen-symbolic",
    search: "system-search-symbolic",
    settings: "emblem-system-symbolic",
    tick: "object-select-symbolic",
  },
};
