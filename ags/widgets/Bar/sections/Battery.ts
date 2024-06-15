import { cx } from "lib/cx";

const battery = await Service.import("battery");

export const Battery = () => {
  // Merge the charging and charged signals into a single signal, because I
  // don't care about the difference.
  const charging = Utils.merge(
    [battery.bind("charging"), battery.bind("charged")],
    (a, b) => a || b
  );
  const percentage = battery.bind("percent");
  const status = percentage.as((value) =>
    value < 10 ? "critical" : value < 25 ? "low" : "normal"
  );

  const icon = Widget.Label({
    class_name: "icon",
    vpack: "center",
    label: "󱐋",
  });

  const label = Widget.Label({
    vpack: "center",
    class_name: "label",
    label: percentage.as((value) => `${Math.round(value)}%`),
  });

  const bar = Widget.ProgressBar({
    vpack: "center",
    class_name: "progress",
    value: percentage.as((value) => (value > 0 ? value / 100 : 0)),
  });

  return Widget.Box({
    class_name: Utils.merge([charging, status], (chargingValue, statusValue) =>
      cx("battery section", chargingValue ? "charging" : statusValue)
    ),
    hpack: "center",
    children: [icon, label, bar],
  });
};
