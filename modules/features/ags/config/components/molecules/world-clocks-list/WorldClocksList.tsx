import { ListBox, ListBoxProps } from "../../hocs/list-box/ListBox";
import { MapKey, MapValue } from "../../../util/type";
import { Variable, bind, exec } from "astal";

import { Gtk } from "astal/gtk4";

const currentDateTimeState = Variable("").poll(
  1000,
  'date --iso-8601="minutes"'
);
const currentWorldClocksState = Variable<{
  readonly currentDateTime: string;
  readonly worldClocks: Array<WorldClock>;
}>({
  currentDateTime: "",
  worldClocks: [],
});

export type WorldClocksListProps = Omit<ListBoxProps, "selectionMode"> & {
  readonly window: Gtk.Window;
};

export const WorldClocksList = (props: WorldClocksListProps) => {
  const { setup, window, ...restProps } = props;

  return (
    <ListBox
      {...restProps}
      title="World Clocks"
      subtitle={bind(currentWorldClocksState).as(
        () =>
          `Current: ${
            exec("timedatectl show -p Timezone --value")
              .split("/")
              .at(-1)
              ?.replace("_", " ") ?? "Unknown"
          }`
      )}
      setup={(self) => {
        setup?.(self);

        // Initially disable polling.
        currentDateTimeState.stopPoll();

        bind(window, "visible").subscribe((visible) => {
          if (visible) {
            currentDateTimeState.startPoll();
          } else {
            currentDateTimeState.stopPoll();
          }
        });

        bind(currentDateTimeState).subscribe((currentDateTime) => {
          // Only update the world clocks if the UTC date time has changed.
          if (
            currentDateTime !== currentWorldClocksState.get().currentDateTime
          ) {
            currentWorldClocksState.set({
              currentDateTime,
              worldClocks: getWorldClocks(currentDateTime),
            });
          }
        });
      }}
      selectionMode={Gtk.SelectionMode.NONE}
    >
      {bind(currentWorldClocksState).as(({ worldClocks }) =>
        worldClocks.map((worldClock) => (
          <ListBox.Item activatable={false} selectable={false}>
            <box cssClasses={["space-x-2"]} hexpand>
              <label
                cssClasses={["font-normal", "text-sm", "text-white"]}
                halign={Gtk.Align.START}
              >
                {worldClock.timeZone.name}
              </label>
              <label
                cssClasses={["font-normal", "text-sm", "text-gray-100"]}
                halign={Gtk.Align.END}
                hexpand
              >
                {worldClock.dateTime}
              </label>
            </box>
          </ListBox.Item>
        ))
      )}
    </ListBox>
  );
};

const timeZones = new Map([
  ["America/Los_Angeles", "Los Angeles"],
  ["Europe/Zurich", "Zurich"],
  ["Asia/Tokyo", "Tokyo"],
] as const);

type WorldClock = {
  readonly dateTime: string;
  readonly timeZone: {
    readonly id: MapKey<typeof timeZones>;
    readonly name: MapValue<typeof timeZones>;
  };
};

const getWorldClocks = (currentDateTime: string): Array<WorldClock> => {
  const date = new Date(currentDateTime);

  return [...timeZones.entries()].map(([id, name]) => {
    const dateTime = date.toLocaleString(undefined, {
      hour12: false,
      hour: "2-digit",
      minute: "2-digit",
      second: undefined,
      timeZone: id,
    });

    return {
      dateTime,
      timeZone: { id, name },
    };
  });
};
