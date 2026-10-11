# Core Instructions

## Rules

- Read `AGENTS.md`, `README.md`, `CONTRIBUTING.md`, and relevant project documentation when they exist.
- Inspect existing code and conventions before proposing or making changes.
- Verify library, API, package, and configuration assumptions with the available tools rather than relying only on memory.
- Prefer focused, reversible changes and stateless inspection commands.
- Present findings, alternatives, and a recommendation before implementation unless the user already approved a concrete plan.
- Ask when requirements are ambiguous or a decision would materially change scope, security, cost, or maintainability.
- Do not build, switch, deploy, commit, push, or otherwise apply system changes without explicit user approval.

## Git

- Use Git commands for inspection by default.
- Do not stage, commit, amend, push, force-push, reset, clean, or stash unless the user explicitly requests it.
- Treat pre-existing changes as user-owned and do not overwrite them.

## Subagents

Pi Herdsman runs agents asynchronously in visible Herdr panes. Available definitions are:

- `generalist`: Complete bounded, approved tasks that do not fit a specialized definition.
- `implementer`: Implement one focused, approved change and perform only permitted checks.
- `researcher`: Research current external information with the configured MCP servers.
- `reviewer`: Review changes for concrete defects without modifying files, using only permitted read-only shell commands.
- `scout`: Locate relevant code, conventions, and tests without modifying files, using only permitted read-only shell commands.

Use `delegate_agent` for narrow tasks that benefit from isolated context, selecting the appropriate definition. Use `continue_agent` for follow-up work with an existing agent. Delegate independent tasks in parallel when useful, but do not delegate work that is faster to do directly. After delegation, continue independent work or end the turn. Results and owner questions are delivered automatically; never poll panes, logs, sessions, or agent tools for completion. Pass relevant source files and exact result references through the coordination tools' `files` field when handing off dependent work.

### Subagent startup issues

Each subagent is a separate Pi process with its own MCP server instances. Starting a subagent can require the user to approve 1Password access to the MCP credentials. Waiting for approval can cause startup to time out and trigger rollback.

- If startup or rollback fails, use the available Herdsman recovery tools to resolve or close the failed generation before retrying.
- If physical identity is unknown and no safe control is available, do not guess or manually target a pane or process. Let Herdsman reconcile the identity and tell the user about the blocker.
- After successful cleanup, retry once; the new attempt may prompt the user for 1Password access again.
- If the retry also fails, clean up where possible and temporarily work without subagents. Never take over assigned work locally while its agent generation remains unresolved.
- Treat these failures as temporary. Try delegation again for a suitable task later, rather than abandoning subagents permanently or repeatedly launching test agents.

## MCP

Native MCP servers expose a small, allowlisted tool surface through `codemode`. Use `searchTools()` or `describeNamespace()` in a Codemode script when an exact tool name or argument is unclear, then call the namespaced `mcp__<server>__<tool>` function.

- Kagi: `kagi_search_fetch` and `kagi_extract` for general web search and page extraction.
- Firecrawl: `firecrawl_developer_search` for documentation, source repositories, issues, pull requests, and related developer material.
- NixOS: `nix` and `nix_versions` for current package, option, flake, cache, store, and version-history information.
- Time: `get_current_time` and `convert_time` for timezone-aware time queries.

Use the NixOS MCP whenever work touches Nix packages, NixOS or Home Manager options, flakes, channels, binary caches, or store paths. Use Kagi and Firecrawl for complementary research rather than repeating the same broad search through both.

Pi, Herdr, and global MCP settings are managed declaratively by Nix. Use `/mcp` for inspection and diagnostics, but propose persistent changes in this repository instead of using actions that attempt to rewrite the managed configuration.

## External codebases

When a dependency must be inspected in depth, clone it into a project-local ignored directory such as `.temp/`, then inspect that checkout. Do not clone external projects into global temporary directories or the project source tree.

## Workflow

1. Determine what to inspect and read the relevant local documentation.
2. Research uncertain or version-sensitive details with MCP tools or focused subagents.
3. Summarize findings, alternatives, and the recommended plan when approval is still needed.
4. Implement only the approved scope, following existing style and structure.
5. Run focused formatting, linting, and tests that do not apply system state.
6. Summarize changes, verification, remaining risks, and any manual follow-up.
