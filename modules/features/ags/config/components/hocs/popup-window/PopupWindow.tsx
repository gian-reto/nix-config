import { Astal, Gdk, Gtk } from "astal/gtk4";
import { BoxProps, RevealerProps, WindowProps } from "astal/gtk4/widget";
import { Variable, bind } from "astal";

import { unreachable } from "../../../util/unreachable";

export type PopupWindowProps = Omit<
  WindowProps,
  "anchor" | "application" | "child" | "cssClasses" | "name"
> &
  Omit<LayoutProps, "onClickedOutside"> & {
    /**
     * The application which the window belongs to.
     */
    readonly application: NonNullable<WindowProps["application"]>;
    /**
     * Unique name of the window.
     */
    readonly name: string;
  };

/**
 * Wraps the given `child` component in a `window` widget with the given `name`,
 * and allows the window to be easily positioned, as well as toggled using an
 * animation.
 */
export const PopupWindow = (props: PopupWindowProps): Gtk.Widget => {
  const {
    anchor,
    application,
    child,
    name,
    exclusivity = Astal.Exclusivity.IGNORE,
    setup,
    transitionDuration,
    transitionType,
    ...restProps
  } = props;
  const { BOTTOM, LEFT, RIGHT, TOP } = Astal.WindowAnchor;

  const selfRef: Variable<Gtk.Window | undefined> = Variable(undefined);
  const isVisible = Variable(false);

  return (
    <window
      {...restProps}
      name={name}
      setup={(self) => {
        setup?.(self);
        selfRef.set(self);
        bind(self, "visible").subscribe((visible) => isVisible.set(visible));
      }}
      anchor={BOTTOM | LEFT | RIGHT | TOP}
      application={application}
      cssClasses={["bg-transparent"]}
      exclusivity={exclusivity}
      keymode={Astal.Keymode.ON_DEMAND}
      layer={Astal.Layer.TOP}
      onKeyPressed={(self, keyval, keycode, state) => {
        if (keyval === Gdk.KEY_Escape) {
          isVisible.set(false);
        }
      }}
    >
      <Layout
        anchor={anchor}
        onClickedOutside={() => {
          isVisible.set(false);
        }}
        onConcealed={() => {
          selfRef.get()?.hide();
        }}
        revealChild={bind(isVisible)}
        transitionDuration={transitionDuration}
        transitionType={transitionType}
      >
        {child}
      </Layout>
    </window>
  );
};

type PopupRevealerProps = RevealerProps & {
  readonly onConcealed?: () => void;
  readonly onRevealed?: () => void;
};

const PopupRevealer = (props: PopupRevealerProps): Gtk.Widget => {
  const {
    child,
    onConcealed,
    onRevealed,
    setup,
    transitionDuration = 200,
    transitionType = Gtk.RevealerTransitionType.SLIDE_DOWN,
    ...restProps
  } = props;

  return (
    <revealer
      {...restProps}
      setup={(self) => {
        setup?.(self);
        bind(self, "childRevealed").subscribe((revealed) =>
          revealed ? onRevealed?.() : onConcealed?.()
        );
      }}
      transitionDuration={transitionDuration}
      transitionType={transitionType}
    >
      {child}
    </revealer>
  );
};

type ClickableSpacerProps = Omit<
  BoxProps,
  "canFocus" | "hexpand" | "vexpand"
> & {
  readonly onClicked?: () => void;
};

const ClickableSpacer = (props: ClickableSpacerProps): Gtk.Widget => {
  const { onClicked, setup, ...restProps } = props;

  const gesture = new Gtk.GestureClick();
  gesture.connect("released", (source) => {
    source.set_state(Gtk.EventSequenceState.CLAIMED);
    onClicked?.();
  });

  return (
    <box
      {...restProps}
      setup={(self) => {
        setup?.(self);
        self.add_controller(gesture);
      }}
      canFocus={false}
      hexpand
      vexpand
    />
  );
};

type LayoutProps = Pick<
  PopupRevealerProps,
  | "child"
  | "onConcealed"
  | "onRevealed"
  | "revealChild"
  | "transitionDuration"
  | "transitionType"
> & {
  readonly anchor:
    | "left-top"
    | "left-center"
    | "left-bottom"
    | "center-top"
    | "center-center"
    | "center-bottom"
    | "right-top"
    | "right-center"
    | "right-bottom";
  readonly onClickedOutside?: () => void;
};

const Layout = (props: LayoutProps): Gtk.Widget => {
  const {
    anchor,
    child,
    onClickedOutside,
    onConcealed,
    onRevealed,
    revealChild,
    transitionDuration,
    transitionType,
  } = props;

  const handleClickSpacer = () => {
    onClickedOutside?.();
  };

  switch (anchor) {
    case "left-top":
      return (
        <box>
          <box hexpand={false} vertical>
            <PopupRevealer
              onConcealed={onConcealed}
              onRevealed={onRevealed}
              revealChild={revealChild}
              transitionDuration={transitionDuration}
              transitionType={
                transitionType ?? Gtk.RevealerTransitionType.SLIDE_DOWN
              }
            >
              {child}
            </PopupRevealer>
            <ClickableSpacer onClicked={handleClickSpacer} />
          </box>
          <ClickableSpacer onClicked={handleClickSpacer} />
        </box>
      );

    case "left-center":
      return (
        <box>
          <centerbox hexpand={false} orientation={Gtk.Orientation.VERTICAL}>
            <ClickableSpacer onClicked={handleClickSpacer} />
            <PopupRevealer
              onConcealed={onConcealed}
              onRevealed={onRevealed}
              revealChild={revealChild}
              transitionDuration={transitionDuration}
              transitionType={
                transitionType ?? Gtk.RevealerTransitionType.SLIDE_RIGHT
              }
            >
              {child}
            </PopupRevealer>
            <ClickableSpacer onClicked={handleClickSpacer} />
          </centerbox>
          <ClickableSpacer onClicked={handleClickSpacer} />
        </box>
      );

    case "left-bottom":
      return (
        <box>
          <box hexpand={false} vertical>
            <ClickableSpacer onClicked={handleClickSpacer} />
            <PopupRevealer
              onConcealed={onConcealed}
              onRevealed={onRevealed}
              revealChild={revealChild}
              transitionDuration={transitionDuration}
              transitionType={
                transitionType ?? Gtk.RevealerTransitionType.SLIDE_UP
              }
            >
              {child}
            </PopupRevealer>
          </box>
          <ClickableSpacer onClicked={handleClickSpacer} />
        </box>
      );

    case "center-top":
      return (
        <centerbox>
          <ClickableSpacer onClicked={handleClickSpacer} />
          <box hexpand={false} vertical>
            <PopupRevealer
              onConcealed={onConcealed}
              onRevealed={onRevealed}
              revealChild={revealChild}
              transitionDuration={transitionDuration}
              transitionType={
                transitionType ?? Gtk.RevealerTransitionType.SLIDE_DOWN
              }
            >
              {child}
            </PopupRevealer>
            <ClickableSpacer onClicked={handleClickSpacer} />
          </box>
          <ClickableSpacer onClicked={handleClickSpacer} />
        </centerbox>
      );

    case "center-center":
      return (
        <centerbox>
          <ClickableSpacer onClicked={handleClickSpacer} />
          <centerbox hexpand={false} orientation={Gtk.Orientation.VERTICAL}>
            <ClickableSpacer onClicked={handleClickSpacer} />
            <PopupRevealer
              onConcealed={onConcealed}
              onRevealed={onRevealed}
              revealChild={revealChild}
              transitionDuration={transitionDuration}
              transitionType={
                transitionType ?? Gtk.RevealerTransitionType.CROSSFADE
              }
            >
              {child}
            </PopupRevealer>
            <ClickableSpacer onClicked={handleClickSpacer} />
          </centerbox>
          <ClickableSpacer onClicked={handleClickSpacer} />
        </centerbox>
      );

    case "center-bottom":
      return (
        <centerbox>
          <ClickableSpacer onClicked={handleClickSpacer} />
          <box hexpand={false} vertical>
            <ClickableSpacer onClicked={handleClickSpacer} />
            <PopupRevealer
              onConcealed={onConcealed}
              onRevealed={onRevealed}
              revealChild={revealChild}
              transitionDuration={transitionDuration}
              transitionType={
                transitionType ?? Gtk.RevealerTransitionType.SLIDE_UP
              }
            >
              {child}
            </PopupRevealer>
          </box>
          <ClickableSpacer onClicked={handleClickSpacer} />
        </centerbox>
      );

    case "right-top":
      return (
        <box>
          <ClickableSpacer onClicked={handleClickSpacer} />
          <box hexpand={false} vertical>
            <PopupRevealer
              onConcealed={onConcealed}
              onRevealed={onRevealed}
              revealChild={revealChild}
              transitionDuration={transitionDuration}
              transitionType={
                transitionType ?? Gtk.RevealerTransitionType.SLIDE_DOWN
              }
            >
              {child}
            </PopupRevealer>
            <ClickableSpacer onClicked={handleClickSpacer} />
          </box>
        </box>
      );

    case "right-center":
      return (
        <box>
          <ClickableSpacer onClicked={handleClickSpacer} />
          <centerbox hexpand={false} orientation={Gtk.Orientation.VERTICAL}>
            <ClickableSpacer onClicked={handleClickSpacer} />
            <PopupRevealer
              onConcealed={onConcealed}
              onRevealed={onRevealed}
              revealChild={revealChild}
              transitionDuration={transitionDuration}
              transitionType={
                transitionType ?? Gtk.RevealerTransitionType.SLIDE_LEFT
              }
            >
              {child}
            </PopupRevealer>
            <ClickableSpacer onClicked={handleClickSpacer} />
          </centerbox>
        </box>
      );

    case "right-bottom":
      return (
        <box>
          <ClickableSpacer onClicked={handleClickSpacer} />
          <box hexpand={false} vertical>
            <ClickableSpacer onClicked={handleClickSpacer} />
            <PopupRevealer
              onConcealed={onConcealed}
              onRevealed={onRevealed}
              revealChild={revealChild}
              transitionDuration={transitionDuration}
              transitionType={
                transitionType ?? Gtk.RevealerTransitionType.SLIDE_UP
              }
            >
              {child}
            </PopupRevealer>
          </box>
        </box>
      );

    default:
      return unreachable(anchor);
  }
};
