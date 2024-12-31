import { ConstructProps, Gtk, astalify } from "astal/gtk4";

import { cx } from "../util/cx";

export type GtkCalendarProps = Omit<_GtkCalendarProps, "cssClasses"> & {
  readonly cssClasses?: string[];
};

export const GtkCalendar = (props: GtkCalendarProps) => {
  const { cssClasses, ...restProps } = props;

  return (
    <_GtkCalendar
      showDayNames
      showHeading
      showWeekNumbers
      {...restProps}
      cssClasses={cx(cssClasses, "gtk-calendar")}
    />
  );
};

type _GtkCalendarProps = ConstructProps<
  Gtk.Calendar,
  Gtk.Calendar.ConstructorProps
>;

const _GtkCalendar = astalify<Gtk.Calendar, Gtk.Calendar.ConstructorProps>(
  Gtk.Calendar
);
