---
description: Review current changes for concrete defects and regressions
argument-hint: "[scope]"
---

Review the current changes. Additional scope: ${ARGUMENTS:-none}.

Inspect the diff and surrounding implementation. Delegate an independent pass to the `reviewer` subagent when the change is non-trivial. Prioritize correctness, regressions, security, compatibility, and missing verification. Report findings by severity with exact locations and practical fixes; if there are no findings, state what was checked.
