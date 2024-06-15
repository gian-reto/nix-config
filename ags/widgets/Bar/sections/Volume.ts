const audio = await Service.import("audio");

export const Volume = () => {
  const label = Widget.Label({
    label: "Vol",
  });

  const slider = Widget.Slider({
    hexpand: true,
    draw_value: false,
    on_change: ({ value }) => (audio.speaker.volume = value),
    setup: (self) =>
      self.hook(audio.speaker, () => {
        self.value = audio.speaker.volume || 0;
      }),
  });

  return Widget.Box({
    class_name: "volume section",
    children: [label, slider],
  });
};
