import { clock } from "lib/variables";

export const DateTime = () => {
  return Widget.Box({
    class_name: "datetime section",
    child: Widget.Label().bind(
      "label",
      clock,
      "value",
      (value) => `${value.format("%a %d. %b %H:%M")}`
    ),
  });
};
