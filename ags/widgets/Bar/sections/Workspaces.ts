import { cx } from "lib/cx";

const hyprland = await Service.import("hyprland");

const go_to_workspace = (id: string | number) => {
  hyprland.messageAsync(`dispatch workspace ${id}`);
};

export const Workspaces = () => {
  const active_id = hyprland.active.workspace.bind("id");
  const workspaces = hyprland.bind("workspaces").as((workspace) =>
    workspace
      .filter(({ id }) => id > 0)
      .sort((a, b) => a.id - b.id)
      .map(({ id }) =>
        Widget.Button({
          on_clicked: () => go_to_workspace(id),
          class_name: active_id.as((value) =>
            cx("workspace", value === id && "active")
          ),
        })
      )
  );

  return Widget.Box({
    class_name: "workspaces section",
    children: workspaces,
  });
};
