import { type Application } from "types/service/applications";
import { launchApp, icon } from "lib/utils";
import { icons } from "lib/icons";

const apps = await Service.import("applications");
const { query } = apps;

export const Favorites = () => {
  const favorites = apps.list.sort((a, b) => b.frequency - a.frequency);

  return Widget.Revealer({
    class_name: "favorites",
    visible: true,
    child: Widget.Box({
      class_name: "rows vertical",
      vertical: true,
      children: [
        Widget.Box({
          class_name: "row horizontal",
          children: favorites.slice(0, 6).map(FavoriteItemButton),
        }),
        Widget.Box({
          class_name: "row horizontal",
          children: favorites.slice(6, 12).map(FavoriteItemButton),
        }),
        Widget.Box({
          class_name: "row horizontal",
          children: favorites.slice(12, 18).map(FavoriteItemButton),
        }),
      ],
    }),
  });
};

export const AppLauncher = () => {
  const MAX_RESULTS = 6;

  const appList = Variable(query(""));
  let first = appList.value[0];

  const AppItem = (app: Application) => {
    return Widget.Revealer(
      { attribute: { app } },
      Widget.Box({ vertical: true }, AppItemButton(app))
    );
  };

  const list = Widget.Box({
    class_name: "results vertical",
    vertical: true,
    children: appList.bind().as((list) => list.map(AppItem)),
    setup: (self) =>
      self.hook(apps, () => (appList.value = query("")), "notify::frequents"),
  });

  return Object.assign(list, {
    filter(text: string | null) {
      first = query(text || "")[0];
      list.children.reduce((acc, curr) => {
        if (!text || acc >= MAX_RESULTS) {
          curr.reveal_child = false;
          return acc;
        }

        if (curr.attribute.app.match(text)) {
          curr.reveal_child = true;
          return ++acc;
        }

        curr.reveal_child = false;
        return acc;
      }, 0);
    },
    launchFirst() {
      launchApp(first);
    },
  });
};

const FavoriteItemButton = (app: Application) =>
  Widget.Button({
    class_name: "button favorite",
    hexpand: true,
    tooltip_text: app.name,
    on_clicked: () => {
      App.closeWindow("launcher");
      launchApp(app);
    },
    child: Widget.Icon({
      class_name: "icon",
      icon: icon(app.icon_name, icons.fallback.executable),
      size: 58,
    }),
  });

const AppItemButton = (app: Application) => {
  const title = Widget.Label({
    class_name: "title",
    label: app.name,
    hexpand: true,
    xalign: 0,
    vpack: "center",
    truncate: "end",
  });

  const description = Widget.Label({
    class_name: "description",
    label: app.description || "",
    hexpand: true,
    max_width_chars: 30,
    wrap: false,
    truncate: "end",
    xalign: 0,
    justification: "left",
    vpack: "center",
  });

  const appIcon = Widget.Icon({
    class_name: "icon",
    icon: icon(app.icon_name, icons.fallback.executable),
    size: 54,
  });

  const textBox = Widget.Box({
    vertical: true,
    vpack: "center",
    children: app.description ? [title, description] : [title],
  });

  return Widget.Button({
    class_name: "button app",
    attribute: { app },
    child: Widget.Box({
      children: [appIcon, textBox],
    }),
    on_clicked: () => {
      App.closeWindow("launcher");
      launchApp(app);
    },
  });
};
