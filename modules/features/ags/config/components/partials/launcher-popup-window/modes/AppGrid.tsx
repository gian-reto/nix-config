import { Variable, bind, derive } from "astal";

import Apps from "gi://AstalApps";
import { Gtk } from "astal/gtk4";
import { GtkScrolledWindow } from "../../../../widgets/GtkScrolledWindow";
import { RevealerProps } from "astal/gtk4/widget";
import { chunk } from "../../../../util/array";
import { getIconFromNameOrPath } from "../../../../util/icon";

const apps = new Apps.Apps();

export type AppGridProps = RevealerProps & {
  readonly window: Gtk.Window;
  readonly onItemClicked?: (self: Gtk.Revealer, app: Apps.Application) => void;
};

export const AppGrid = (props: AppGridProps) => {
  const { onItemClicked, window, setup, ...restProps } = props;

  const selfRef: Variable<Gtk.Revealer | undefined> = Variable(undefined);

  const chunkedSortedApps = derive(
    [bind(window, "visible"), bind(apps, "list")],
    (window, list) =>
      chunk(
        list.sort((a, b) => b.frequency - a.frequency),
        6
      )
  );

  return (
    <revealer
      {...restProps}
      setup={(self) => {
        setup?.(self);
        selfRef.set(self);
      }}
    >
      {bind(selfRef).as(
        (self) =>
          self && (
            <GtkScrolledWindow
              halign={Gtk.Align.CENTER}
              hexpand={false}
              hscrollbarPolicy={Gtk.PolicyType.NEVER}
              minContentHeight={240}
              maxContentHeight={240}
              overflow={Gtk.Overflow.HIDDEN}
              propagateNaturalWidth
              vscrollbarPolicy={Gtk.PolicyType.EXTERNAL}
            >
              <box
                halign={Gtk.Align.FILL}
                hexpand
                valign={Gtk.Align.START}
                vexpand={false}
              >
                {bind(chunkedSortedApps).as((rows) => (
                  <box
                    halign={Gtk.Align.FILL}
                    hexpand
                    homogeneous
                    valign={Gtk.Align.START}
                    vexpand={false}
                    vertical
                  >
                    {rows.map((row) => (
                      <box
                        halign={Gtk.Align.FILL}
                        hexpand
                        homogeneous
                        valign={Gtk.Align.START}
                        vexpand={false}
                      >
                        {row.map((app) => {
                          const icon = getIconFromNameOrPath(
                            app.iconName,
                            window,
                            64
                          );

                          return (
                            <button
                              cssClasses={[
                                "bg-transparent",
                                "p-0",
                                "rounded-2xl",
                                "hover:bg-gray-950",
                              ]}
                              halign={Gtk.Align.CENTER}
                              hexpand={false}
                              tooltipText={app.name}
                              valign={Gtk.Align.CENTER}
                              vexpand={false}
                              onClicked={() => {
                                onItemClicked?.(self, app);
                              }}
                            >
                              <image
                                cssClasses={[
                                  "gtk-icon-style-regular",
                                  "gtk-icon-size-5xl",
                                  "min-w-20",
                                  "min-h-20",
                                ]}
                                file={
                                  icon.type === "file" ? icon.path : undefined
                                }
                                halign={Gtk.Align.CENTER}
                                hexpand={false}
                                paintable={
                                  icon.type === "paintable"
                                    ? icon.paintable
                                    : undefined
                                }
                                iconName={app.iconName}
                                valign={Gtk.Align.CENTER}
                                vexpand={false}
                              />
                            </button>
                          );
                        })}
                      </box>
                    ))}
                  </box>
                ))}
              </box>
            </GtkScrolledWindow>
          )
      )}
    </revealer>
  );
};
