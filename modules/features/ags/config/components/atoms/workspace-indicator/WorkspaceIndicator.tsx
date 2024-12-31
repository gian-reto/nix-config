import { Variable, bind } from "astal";

import { BoxProps } from "astal/gtk4/widget";
import { Gtk } from "astal/gtk4";
import Hyprland from "gi://AstalHyprland";
import { VariableMap } from "../../../util/variable-map";
import { cx } from "../../../util/cx";
import { difference } from "../../../util/array";

const hyprland = Hyprland.get_default();

export type WorkspaceIndicatorProps = Omit<BoxProps, "cssClasses"> & {
  readonly cssClasses?: string[];
};

export const WorkspaceIndicator = (props: WorkspaceIndicatorProps) => {
  const { cssClasses, ...restProps } = props;

  /**
   * A map of workspace IDs to their corresponding `WorkspaceIndicatorItem`.
   */
  const currentWorkspaceIndicatorItems = new VariableMap<
    number,
    ReturnType<typeof Item>
  >(
    // Initialize the map with the current workspaces.
    calculateWorkspaceChanges(hyprland.workspaces).addedWorkspaceIds.map(
      (id) => [id, <Item workspaceId={id} />]
    )
  );

  const workspacesUnsubscriber = bind(hyprland, "workspaces").subscribe(
    (currentWorkspaces) => {
      const { addedWorkspaceIds, removedWorkspaceIds } =
        calculateWorkspaceChanges(
          currentWorkspaces,
          currentWorkspaceIndicatorItems
        );

      for (const id of addedWorkspaceIds) {
        currentWorkspaceIndicatorItems.set(id, <Item workspaceId={id} />);
      }
      for (const id of removedWorkspaceIds) {
        currentWorkspaceIndicatorItems.delete(id);
      }
    }
  );

  return (
    <box
      {...restProps}
      baselinePosition={Gtk.BaselinePosition.CENTER}
      cssClasses={cx(cssClasses, "space-x-1")}
      orientation={Gtk.Orientation.HORIZONTAL}
      onDestroy={workspacesUnsubscriber}
    >
      {bind(currentWorkspaceIndicatorItems).as((items) =>
        items.sort(([aId], [bId]) => aId - bId).map(([, item]) => item)
      )}
    </box>
  );
};

type WorkspaceIndicatorItemProps = {
  /**
   * The ID of the workspace represented by the item.
   */
  workspaceId: number;
};

const Item = ({ workspaceId }: WorkspaceIndicatorItemProps) => {
  const focusedState = Variable.derive(
    [bind(hyprland, "focusedWorkspace")],
    (focusedWorkspace) => focusedWorkspace.id === workspaceId
  );

  return (
    <button
      cssClasses={bind(focusedState).as((isFocused) =>
        cx(
          isFocused ? "bg-white" : "bg-gray-200",
          isFocused ? "min-w-9" : "min-w-2",
          "min-h-2",
          "p-0",
          "rounded-full",
          "transition-sizes",
          "hover:bg-white"
        )
      )}
      halign={Gtk.Align.START}
      hexpand={false}
      valign={Gtk.Align.CENTER}
      vexpand={false}
      onClicked={() => {
        hyprland.message_async(`dispatch workspace ${workspaceId}`, null);
      }}
    />
  );
};

/**
 * Get the list of Hyprland workspace IDs that don't have a corresponding
 * `WorkspaceIndicatorItem` yet, and the list of workspace IDs that have a
 * corresponding `WorkspaceIndicatorItem` but don't exist anymore.
 */
const calculateWorkspaceChanges = (
  workspaces: { readonly id: number }[],
  workspaceIndicatorItems?: VariableMap<number, ReturnType<typeof Item>>
): { addedWorkspaceIds: number[]; removedWorkspaceIds: number[] } => {
  // Interpolate IDs (between 1 and the highest ID + 1) in the list of Hyprland
  // workspaces.
  const workspaceIds = Array.from(
    {
      length: workspaces.reduce((acc, curr) => Math.max(acc, curr.id), 0) + 1,
    },
    (_, i) => i + 1
  );

  if (workspaceIndicatorItems === undefined) {
    return { addedWorkspaceIds: workspaceIds, removedWorkspaceIds: [] };
  }

  // Workspace IDs that are currently represented by a `WorkspaceIndicatorItem`.
  const workspaceIndicatorItemIds = workspaceIndicatorItems
    .get()
    .map(([id]) => id);

  return {
    addedWorkspaceIds: difference(workspaceIds, workspaceIndicatorItemIds),
    removedWorkspaceIds: difference(workspaceIndicatorItemIds, workspaceIds),
  };
};
