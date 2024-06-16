const audio = await Service.import("audio");

export const Volume = () => {
  const muted = audio.speaker.bind("is_muted");
  const volume = audio.speaker.bind("volume").as((value) => value * 100);
  const status = Utils.merge([muted, volume], (mutedValue, volumeValue) =>
    mutedValue ? "muted" : volumeValue < 50 ? "low" : "high"
  );

  const icon = Widget.Label({
    class_name: "icon",
    vpack: "center",
    vexpand: false,
    label: status.as((value) =>
      value === "muted" ? "󰖁" : value === "low" ? "󰖀" : "󰕾"
    ),
  });

  const label = Widget.Label({
    class_name: "label",
    vpack: "fill",
    vexpand: true,
    yalign: 0.7,
    label: volume.as((value) => `${Math.round(value)}%`),
  });

  const slider = Widget.Slider({
    class_name: "slider",
    vpack: "center",
    vexpand: true,
    draw_value: false,
    on_change: ({ value }) => (audio.speaker.volume = value),
    setup: (self) =>
      self.hook(audio.speaker, () => {
        self.value = audio.speaker.volume || 0;
      }),
  });

  return Widget.Box({
    class_name: "volume section horizontal",
    vpack: "fill",
    vexpand: true,
    children: [icon, label, slider],
  });
};
