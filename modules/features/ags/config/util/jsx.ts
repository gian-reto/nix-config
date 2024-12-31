import { Fragment } from "astal/gtk4/jsx-runtime";

export type PropsWithChildren<TProps> = TProps & Parameters<typeof Fragment>[0];
