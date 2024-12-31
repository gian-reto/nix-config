import { Binding, Variable, bind, derive } from "astal";
import { GtkListBox, GtkListBoxProps } from "../../../../widgets/GtkListBox";

import Apps from "gi://AstalApps";
import { ButtonProps } from "astal/gtk4/widget";
import { Gtk } from "astal/gtk4";
import { GtkListBoxRow } from "../../../../widgets/GtkListBoxRow";
import Pango from "gi://Pango?version=1.0";
import { cx } from "../../../../util/cx";
import { getIconFromNameOrPath } from "../../../../util/icon";

const apps = new Apps.Apps({
  categoriesMultiplier: 0,
  descriptionMultiplier: 0.25,
  entryMultiplier: 0,
  executableMultiplier: 0.75,
  keywordsMultiplier: 0.75,
  nameMultiplier: 2,
});

export type AppSearchProps = Omit<GtkListBoxProps, "cssClasses"> & {
  readonly cssClasses?: string[];
  readonly searchTerm: Binding<string>;
  readonly window: Gtk.Window;
  readonly onResultsChanged?: (
    self: Gtk.ListBox,
    results: ReadonlyArray<{
      readonly data: Apps.Application;
      readonly score: number;
    }>
  ) => void;
  readonly onResultClicked?: (self: Gtk.ListBox, app: Apps.Application) => void;
};

export const AppSearch = (props: AppSearchProps) => {
  const {
    cssClasses,
    setup,
    searchTerm,
    window,
    onResultsChanged,
    onResultClicked,
    ...restProps
  } = props;

  const MAX_RESULTS = 6;

  const selfRef: Variable<Gtk.ListBox | undefined> = Variable(undefined);

  const scoredAppsState = derive(
    [bind(window, "visible"), bind(apps, "list"), searchTerm],
    (window, list, searchTerm) =>
      new Map(
        list.map((app) => [
          app.name,
          {
            data: app,
            score: apps.fuzzy_score(searchTerm, app),
          },
        ])
      )
  );
  const searchResultsState = derive(
    [scoredAppsState],
    (scoredApps) =>
      new Set(
        [...scoredApps.values()]
          .sort((a, b) => b.score - a.score)
          .slice(0, MAX_RESULTS)
          .filter((app) => app.score > 0)
          .map((app) => app.data.name)
      )
  );

  return (
    <GtkListBox
      {...restProps}
      setup={(self) => {
        setup?.(self);
        selfRef.set(self);

        self.set_sort_func(
          (a, b) =>
            (scoredAppsState.get().get(b.get_name())?.score ?? 0) -
            (scoredAppsState.get().get(a.get_name())?.score ?? 0)
        );
        scoredAppsState.subscribe(() => {
          self.invalidate_sort();
        });
        searchResultsState.subscribe((searchResults) => {
          onResultsChanged?.(
            self,
            [...searchResults.values()].flatMap((result) => {
              const app = scoredAppsState.get().get(result);
              if (!app) return [];

              return [
                {
                  data: app.data,
                  score: app.score,
                },
              ];
            })
          );
        });
      }}
      cssClasses={cx(cssClasses, "bg-transparent")}
    >
      {bind(derive([selfRef, bind(apps, "list")])).as(
        ([self, appsList]) =>
          self &&
          appsList.map((app) => (
            <GtkListBoxRow
              name={app.name}
              cssClasses={["bg-transparent", "p-0"]}
            >
              <revealer
                revealChild={bind(searchResultsState).as((searchResults) =>
                  searchResults.has(app.name)
                )}
              >
                <SearchResult
                  app={app}
                  window={window}
                  onButtonPressed={() => {
                    onResultClicked?.(self, app);
                  }}
                />
              </revealer>
            </GtkListBoxRow>
          ))
      )}
    </GtkListBox>
  );
};

type SearchResultProps = ButtonProps & {
  readonly app: Apps.Application;
  readonly window: Gtk.Window;
};

export const SearchResult = (props: SearchResultProps) => {
  const { app, window, onClicked, ...restProps } = props;

  const icon = getIconFromNameOrPath(app.iconName, window, 64);

  return (
    <button
      {...restProps}
      cssClasses={[
        "bg-transparent",
        "px-0",
        "py-0",
        "rounded-2xl",
        "hover:bg-gray-950",
      ]}
    >
      <box cssClasses={["space-x-1"]}>
        <image
          cssClasses={[
            "gtk-icon-style-regular",
            "gtk-icon-size-5xl",
            "min-w-20",
            "min-h-20",
          ]}
          file={icon.type === "file" ? icon.path : undefined}
          halign={Gtk.Align.START}
          hexpand={false}
          paintable={icon.type === "paintable" ? icon.paintable : undefined}
          iconName={app.iconName}
          valign={Gtk.Align.CENTER}
          vexpand={false}
        />
        <box
          cssClasses={["space-y-1"]}
          halign={Gtk.Align.FILL}
          hexpand
          valign={Gtk.Align.CENTER}
          vexpand={false}
          vertical
        >
          <label
            cssClasses={["font-normal", "text-white", "text-lg"]}
            ellipsize={Pango.EllipsizeMode.END}
            halign={Gtk.Align.START}
            hexpand
            justify={Gtk.Justification.LEFT}
            maxWidthChars={30}
            valign={Gtk.Align.CENTER}
            vexpand={false}
            wrap={false}
          >
            {app.name}
          </label>
          {app.description && (
            <label
              cssClasses={["font-semibold", "text-gray-200", "text-sm"]}
              ellipsize={Pango.EllipsizeMode.END}
              halign={Gtk.Align.START}
              hexpand
              justify={Gtk.Justification.LEFT}
              maxWidthChars={30}
              valign={Gtk.Align.CENTER}
              vexpand={false}
              wrap={false}
            >
              {app.description}
            </label>
          )}
        </box>
      </box>
    </button>
  );
};
