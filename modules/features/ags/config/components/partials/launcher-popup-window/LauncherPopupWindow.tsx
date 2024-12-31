import { Astal, Gtk } from "astal/gtk4";
import {
  PopupWindow,
  PopupWindowProps,
} from "../../hocs/popup-window/PopupWindow";
import { Variable, bind, derive } from "astal";

import { AppGrid } from "./modes/AppGrid";
import { AppSearch } from "./modes/AppSearch";
import Apps from "gi://AstalApps";
import { cx } from "../../../util/cx";
import { unreachable } from "../../../util/unreachable";

const apps = new Apps.Apps();

export type LauncherPopupWindowProps = Omit<
  PopupWindowProps,
  "anchor" | "name" | "exclusivity"
>;

export const LauncherPopupWindow = (
  props: LauncherPopupWindowProps
): Gtk.Widget => {
  const { setup, ...restProps } = props;

  const selfRef: Variable<Gtk.Window | undefined> = Variable(undefined);
  const entryRef: Variable<Gtk.Entry | undefined> = Variable(undefined);

  const entryTextState = Variable<string>("");
  const entryDirtyState: Variable<boolean> = derive(
    [entryTextState],
    (entryText) => {
      if (entryText === "") {
        return false;
      }

      return true;
    }
  );

  const launcherModeState: Variable<"app-grid" | "app-search"> = derive(
    [entryTextState],
    (entryText) => {
      if (entryText === "") {
        return "app-grid";
      }

      return "app-search";
    }
  );

  const topAppSearchResultState = Variable<Apps.Application | undefined>(
    undefined
  );

  const close = () => {
    selfRef?.get()?.set_visible(false);
  };

  const focusEntry = () => {
    const entry = entryRef?.get();
    if (!entry) return;

    entry.set_position(-1);
    entry.select_region(0, -1);
    entry.grab_focus();
  };

  return (
    <PopupWindow
      {...restProps}
      name="launcher"
      setup={(self) => {
        setup?.(self);
        selfRef.set(self);

        bind(self, "visible").subscribe((visible) => {
          if (visible) {
            focusEntry();
            apps.reload();
          }
        });
      }}
      anchor="center-center"
      exclusivity={Astal.Exclusivity.EXCLUSIVE}
    >
      {bind(selfRef).as(
        (self) =>
          self && (
            <box
              cssClasses={["bg-black/80", "p-5", "rounded-3xl"]}
              halign={Gtk.Align.CENTER}
              hexpand={false}
              valign={Gtk.Align.CENTER}
              vexpand={false}
              vertical
            >
              <entry
                setup={(self) => {
                  entryRef.set(self);
                }}
                cssClasses={bind(entryDirtyState).as((dirty) =>
                  cx("launcher-entry", dirty && "dirty")
                )}
                hasFrame={false}
                halign={Gtk.Align.FILL}
                hexpand
                placeholderText="Search"
                primaryIconName="system-search-symbolic"
                valign={Gtk.Align.START}
                vexpand={false}
                onActivate={(self) => {
                  const launcherMode = launcherModeState.get();
                  switch (launcherMode) {
                    case "app-grid":
                      // Do nothing.
                      break;

                    case "app-search":
                      topAppSearchResultState.get()?.launch();
                      break;

                    default:
                      unreachable(launcherMode);
                  }

                  close();
                }}
                onNotifyText={(self) =>
                  entryTextState.set(self.get_text() || "")
                }
              />
              <AppGrid
                revealChild={bind(launcherModeState).as(
                  (launcherMode) => launcherMode === "app-grid"
                )}
                window={self}
                onItemClicked={(self, app) => {
                  app.launch();
                  close();
                }}
              />
              <revealer
                revealChild={bind(launcherModeState).as(
                  (launcherMode) => launcherMode !== "app-grid"
                )}
              >
                <box
                  halign={Gtk.Align.FILL}
                  hexpand
                  valign={Gtk.Align.START}
                  vexpand={false}
                  vertical
                >
                  {bind(launcherModeState).as((launcherMode) => {
                    switch (launcherMode) {
                      case "app-grid":
                        // App grid is always present, but not always revealed.
                        return <></>;
                      case "app-search":
                        return (
                          <AppSearch
                            searchTerm={bind(entryTextState)}
                            window={self}
                            onResultClicked={(self, app) => {
                              app.launch();
                              close();
                            }}
                            onResultsChanged={(self, results) =>
                              topAppSearchResultState.set(
                                results.reduce((acc, curr) =>
                                  acc.score > curr.score ? acc : curr
                                ).data
                              )
                            }
                          />
                        );
                      default:
                        return unreachable(launcherMode);
                    }
                  })}
                </box>
              </revealer>
            </box>
          )
      )}
    </PopupWindow>
  );
};
