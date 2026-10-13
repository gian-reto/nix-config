# Pi AppArmor executor

Apply a consumer-supplied AppArmor profile to Pi's built-in file (`read`, `write`, `grep`, etc.) and shell (`bash`, `powershell`) operations. Pi itself, as well as its MCP servers, remain unconstrained by that profile. This package does not contain a default policy, so it has to be supplied by the consumer via a configuration file.

Most file permission systems for Pi usually operate at a higher level, and only disallow access to files based on file paths at a tool level. Others apply sandboxing, but not for all tools which access the filesystem. The AppArmor executor enforces restrictions at the operating system level, and wraps all built-in tools, providing an additional layer of security for file and shell operations within Pi.

## Configuration

Install the package through Pi's `packages` setting:

```json
{
  "packages": ["/path/to/pi-apparmor-executor"]
}
```

Create `~/.pi/agent/pi-apparmor-executor/config.json` with the profile name:

```json
{
  "profile": "my-tool-profile"
}
```

The configuration directory follows Pi's public `getAgentDir()` API, including the `PI_CODING_AGENT_DIR` override.

The consumer must load the respective profile in enforce mode. Missing configuration, failed launches and unexpected worker labels produce errors, and there is no unconfined fallback.

Requirements:

- Linux with AppArmor enabled and a loaded, enforced profile.
- Node.js 24 or later for the TypeScript worker.
- `aa-exec`, `node`, `fd` and `rg` on a trusted `PATH`.

Commands are resolved by name. Keep their directories ahead of writable or project-controlled directories in Pi's launch environment. In particular, an untrusted `aa-exec` would run before the worker's confinement check.

## Execution

The eight built-ins (`bash`, `powershell`, `read`, `write`, `edit`, `grep`, `find` and `ls`) are wrapped to use short-lived confined helpers for their file and process operations. Interactive `!` and `!!` commands use the same executor, and Codemode uses the same replacements through Pi's normal tool registry. Native Pi tool logic remains in Pi.

Public SDK operations hooks preserve native context, schemas, structured results, image processing, output limits, edit queues and shell streaming. `grep` has a focused adapter because its native ripgrep launch has no operations hook.

Edit previews use a confined, read-only execution of the native edit algorithm, displayed with the public SDK diff renderer. Actual edit results replace pending previews. No private SDK imports or patches are needed.

## Boundary

This is tool-only isolation, not a sandbox around Pi. Other extensions, MCP implementations and artifact readers remain outside the helpers. A filesystem-capable MCP or an unconfined extension that reads an arbitrary supplied path is not protected by these replacements. Note: Workers inherit Pi's environment.

The consumer is responsible for the policy's restrictions, including subprocess inheritance, namespace and broker access, and protection of trusted extensions, settings and command paths. Do not treat this as a complete boundary against hostile extensions or every file-access interface.

## Repository integration

`modules/features/ai/pi/default.nix` packages this extension, provides the trusted command `PATH`, installs the extension's `config.json` and deploys the separate [AppArmor policy](../../profile.apparmor). The wrapper also checks the kernel feature required by that policy's user-namespace restrictions. Neither deployment nor that policy-specific check belongs to the reusable extension package.

The repository policy protects common sensitive files (`.env`, etc.) and Pi control files, and blocks common execution brokers, as well as daemon-backed Nix builds.

## Development

From the repository root:

```sh
nix develop
cd modules/features/ai/pi/extensions/pi-apparmor-executor
pnpm install --frozen-lockfile --ignore-scripts
pnpm check
pnpm format
```
