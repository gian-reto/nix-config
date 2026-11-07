# AI configuration

The feature configures [Pi](https://github.com/earendil-works/pi) and [Herdr](https://github.com/herdrdev) with the following notable features:

- Subagents via [`pi-herdsman`](https://github.com/boadij/pi-herdsman).
- Secrets passed as environment variables via 1Password, only resolved by the outermost process (usually Herdr), and inherited by nested processes such as root Pi instances and Pi subagent instances.
- Security hardening by routing every built-in tool execution (e.g. `read`, `write`, and especially `bash`) through `pi-apparmor-executor`.
- Permission management via [`pi-permission-system`](https://github.com/gotgenes/pi-packages/tree/main/packages/pi-permission-system), including rerouting of permission requests from Pi subagents to the given root Pi instance.
