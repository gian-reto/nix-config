# Pi Herdr permissions

Reports visible permission dialogs as blocked through Herdr's existing Pi integration. This is a stopgap for [pi-permission-system issue #658](https://github.com/gotgenes/pi-packages/issues/658).

## Development

From the repository root:

```sh
nix develop
cd modules/features/ai/pi/extensions/pi-herdr-permissions
pnpm install --frozen-lockfile --ignore-scripts
pnpm check
```

The local development dependencies provide Pi and Node types for TypeScript and editor support. Pi supplies its API at runtime, so this extension has no runtime dependencies or compilation step. Home Manager installs the directory, and Pi discovers its `index.ts` entry point.

Only the TUI session hosting a visible permission dialog is marked blocked, including dialogs forwarded from child agents. The requesting child pane and pi-herdsman's `ask_owner` state are not covered.
