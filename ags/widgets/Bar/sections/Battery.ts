import { cx } from "lib/cx";

const battery = await Service.import("battery");

export const Battery = () => {
  // Merge the charging and charged signals into a single signal, because I
  // don't care about the difference.
  const charging = Utils.merge(
    [battery.bind("charging"), battery.bind("charged")],
    (a, b) => a || b
  );
  const percentage = battery
    .bind("percent")
    .transform((value) => (value < 0 ? 100 : value));
  const status = percentage.as((value) =>
    value < 10 ? "critical" : value < 25 ? "low" : "normal"
  );

  const icon = Widget.Label({
    class_name: "icon",
    vpack: "center",
    vexpand: false,
    label: "󱐋",
  });

  const label = Widget.Label({
    class_name: "label",
    vpack: "fill",
    vexpand: true,
    yalign: 0.7,
    label: percentage.as((value) => `${Math.round(value)}%`),
  });

  const bar = Widget.ProgressBar({
    class_name: "progress",
    vpack: "center",
    vexpand: true,
    value: percentage.as((value) => (value > 0 ? value / 100 : 0)),
  });

  return Widget.Box({
    class_name: Utils.merge([charging, status], (chargingValue, statusValue) =>
      cx("battery section horizontal", chargingValue ? "charging" : statusValue)
    ),
    vpack: "fill",
    vexpand: true,
    children: [icon, label, bar],
  });
};
