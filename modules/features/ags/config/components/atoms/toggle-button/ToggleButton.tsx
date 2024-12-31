import { Astal, Gdk, Gtk } from "astal/gtk4";
import { Binding, Variable, bind, derive } from "astal";
import {
  BoxProps,
  ImageProps,
  LabelProps,
  RevealerProps,
} from "astal/gtk4/widget";

import { GtkSeparator } from "../../../widgets/GtkSeparator";
import { GtkSpinner } from "../../../widgets/GtkSpinner";
import Pango from "gi://Pango?version=1.0";
import { cx } from "../../../util/cx";

export type ToggleButtonProps = Omit<
  BoxProps,
  "child" | "children" | "onClicked"
> & {
  readonly active?: boolean | Binding<boolean>;
  readonly expandable?: boolean;
  readonly iconName: string | Binding<string>;
  readonly isExpanded?: boolean | Binding<boolean>;
  readonly label: string | Binding<string>;
  readonly onClicked?: (self: Astal.Box, state: Gdk.ButtonEvent) => void;
  readonly onCollapsed?: (self: Astal.Box, state: Gdk.ButtonEvent) => void;
  readonly onExpanded?: (self: Astal.Box, state: Gdk.ButtonEvent) => void;
};

export const ToggleButton = (props: ToggleButtonProps): Gtk.Widget => {
  const {
    active = false,
    expandable = false,
    iconName,
    isExpanded = false,
    label,
    onClicked,
    onCollapsed,
    onExpanded,
    ...restProps
  } = props;

  const activeState = derive(
    [typeof active === "boolean" || !active ? bind(Variable(active)) : active],
    (active) => active
  );

  const expandedState = derive(
    [
      typeof isExpanded === "boolean" || !isExpanded
        ? bind(Variable(isExpanded))
        : isExpanded,
    ],
    (isExpanded) => isExpanded
  );

  return (
    <box {...restProps}>
      <box
        cssClasses={bind(activeState).as((active) => [
          active ? "bg-primary-3" : "bg-gray-500",
          "min-w-24",
          "pl-5",
          "pr-4",
          "py-4",
          expandable ? "rounded-l-full" : "rounded-full",
          "space-x-3",
          "transition-colors",
          active ? "hover:bg-primary-2" : "hover:bg-gray-400",
        ])}
        halign={Gtk.Align.FILL}
        hexpand
        valign={Gtk.Align.FILL}
        vexpand={false}
        onButtonPressed={onClicked}
      >
        <image
          halign={Gtk.Align.START}
          hexpand={false}
          iconName={iconName}
          valign={Gtk.Align.CENTER}
          vexpand={false}
        />
        <label
          cssClasses={["font-semibold", "text-white", "text-sm"]}
          ellipsize={Pango.EllipsizeMode.END}
          halign={Gtk.Align.START}
          hexpand
          maxWidthChars={expandable ? 8 : 14}
          valign={Gtk.Align.CENTER}
          vexpand={false}
        >
          {label}
        </label>
      </box>
      {expandable && (
        <box
          cssClasses={bind(activeState).as((active) => [
            active ? "bg-primary-2" : "bg-gray-400",
            "border-l",
            active ? "border-primary-1" : "border-gray-300",
            "px-3",
            "py-4",
            "rounded-r-full",
            "transition-colors",
            active ? "hover:bg-primary-1" : "hover:bg-gray-300",
          ])}
          halign={Gtk.Align.END}
          hexpand={false}
          valign={Gtk.Align.FILL}
          vexpand={false}
          onButtonPressed={(self, state) => {
            const newExpandedState = !expandedState.get();

            expandedState.set(newExpandedState);

            if (newExpandedState) {
              onExpanded?.(self, state);
            } else {
              onCollapsed?.(self, state);
            }
          }}
        >
          <image
            halign={Gtk.Align.CENTER}
            hexpand={false}
            iconName="go-next-symbolic"
            valign={Gtk.Align.CENTER}
            vexpand={false}
          />
        </box>
      )}
    </box>
  );
};

export type ToggleButtonMenuProps = Omit<RevealerProps, "transitionType"> & {
  /**
   * Whether the associated toggle button is active.
   */
  readonly active?: boolean | Binding<boolean>;
  /**
   * An additional footer widget, separated from the main content by a
   * separator.
   */
  readonly footer?: Gtk.Widget | Binding<Gtk.Widget> | undefined;
  /**
   * Icon name for the menu's header bar.
   */
  readonly iconName: ImageProps["iconName"];
  /**
   * Whether to show a spinner next to the title. Defaults to `false`.
   */
  readonly spinning?: boolean | Binding<boolean>;
  /**
   * Menu header bar title.
   */
  readonly title: LabelProps["label"];
};

const ToggleButtonMenu = (props: ToggleButtonMenuProps): Gtk.Widget => {
  const {
    active,
    child,
    footer,
    iconName,
    revealChild,
    spinning,
    title,
    ...restProps
  } = props;

  const activeState = derive(
    [
      typeof active === "boolean" || !active
        ? bind(Variable(active ?? false))
        : active,
    ],
    (active) => active
  );

  const spinningState = derive(
    [
      typeof spinning === "boolean" || !spinning
        ? bind(Variable(spinning ?? false))
        : spinning,
    ],
    (spinning) => spinning
  );

  return (
    <revealer
      {...restProps}
      revealChild={revealChild}
      transitionType={Gtk.RevealerTransitionType.SLIDE_DOWN}
    >
      <box
        cssClasses={["bg-gray-400", "mt-3", "p-0", "rounded-3xl", "space-y-3"]}
        overflow={Gtk.Overflow.HIDDEN}
        vertical
      >
        <box cssClasses={["pt-3", "px-3", "space-x-3"]}>
          <box
            cssClasses={bind(activeState).as((active) => [
              active ? "bg-primary-3" : "bg-gray-300",
              "rounded-full",
              "p-2",
            ])}
            halign={Gtk.Align.START}
            hexpand={false}
            valign={Gtk.Align.CENTER}
            vexpand={false}
          >
            <image
              cssClasses={["text-2xl"]}
              halign={Gtk.Align.CENTER}
              hexpand={false}
              iconName={iconName}
              valign={Gtk.Align.CENTER}
              vexpand={false}
            />
          </box>
          <label
            cssClasses={["font-bold", "text-white", "text-xl"]}
            halign={Gtk.Align.START}
            hexpand={false}
            label={title}
            valign={Gtk.Align.CENTER}
            vexpand={false}
          />
          {bind(spinningState).as((spinning) => (
            <box
              halign={Gtk.Align.FILL}
              hexpand
              valign={Gtk.Align.CENTER}
              vexpand={false}
            >
              <GtkSpinner
                cssClasses={["text-white"]}
                halign={Gtk.Align.START}
                hexpand={false}
                spinning={spinning}
                valign={Gtk.Align.CENTER}
                vexpand={false}
                visible={spinning}
              />
            </box>
          ))}
        </box>
        <box cssClasses={["px-3", "pb-3"]} vertical>
          {child}
          {footer && (
            <box cssClasses={["pt-2"]} vertical>
              <GtkSeparator
                cssClasses={["mb-2", "mx-2.5"]}
                orientation={Gtk.Orientation.HORIZONTAL}
              />
              {footer}
            </box>
          )}
        </box>
      </box>
    </revealer>
  );
};

export type ToggleButtonMenuItemProps = Omit<BoxProps, "cssClasses"> & {
  readonly cssClasses?: string[];
  readonly onClicked?: (self: Astal.Box, state: Gdk.ButtonEvent) => void;
};

const ToggleButtonMenuItem = (props: ToggleButtonMenuItemProps): Gtk.Widget => {
  const { cssClasses, child, children, onClicked, ...restProps } = props;

  return (
    <box
      {...restProps}
      cssClasses={cx(
        cssClasses,
        "bg-gray-400",
        "px-3",
        "py-2",
        "rounded-xl",
        "transition-colors",
        "hover:bg-gray-300"
      )}
      onButtonPressed={(self, state) => {
        onClicked?.(self, state);
      }}
    >
      {child || children}
    </box>
  );
};

ToggleButtonMenu.Item = ToggleButtonMenuItem;
export { ToggleButtonMenu };
