# ADR-0001: Reference, not automation

- Status: Accepted
- Date: 2026-07-02 (recorded 2026-07-12; salvaged from the since-deleted `IN_TRANSIT.md`)
- Deciders: nranthony + agent

## Context

This repo began life as an **automated scaffolder**: `scripts/apply.sh` copied
`templates/` into a target repo and regenerated `CLAUDE.md` files via a sync script.
Auditing it surfaced real footguns:

- **Unconditional CLAUDE.md overwrite.** The sync step rewrote the `CLAUDE.md` next to
  every `AGENTS.md` into a 2-line stub, ungated by skip logic or `--force`. Any
  substantive hand-written `CLAUDE.md` (several repos had 100–250-line ones) would be
  flattened the moment a sibling `AGENTS.md` appeared.
- **`--force` wiped customization** across every template-managed file.
- **Shipping CI turned on GitHub Actions** in target repos, failing red until synced
  files were committed.
- **`CODEOWNERS * @nranthony`** was wrong for repos owned by other orgs and silently
  changed PR approval requirements.
- **Unscoped `find`** wrote `CLAUDE.md` into vendored dirs (`node_modules`, etc.).

The root cause was structural, not fixable with better flags: a blind copy loop cannot
know a target repo's context.

## Decision

This repo is a **reference handed to an agent**, never a script that mutates repos.
The agent working inside a target repo — which already knows that repo in detail —
reads `reference/` and `templates/` as the desired shape and applies the conventions
**by hand**, adapting or skipping pieces per the lean-core tiers and brownfield
process in the reference.

All automation was removed: `scripts/apply.sh`, `templates/scripts/sync-agent-files.sh`,
and `templates/.github/workflows/ci.yml`. The reference explicitly recommends *against*
a `CLAUDE.md` sync script (a read-only CI assertion is the acceptable ceiling).

## Consequences

- Setup is slower and manual, but each application is context-aware; the footgun class
  above is eliminated by construction.
- `templates/` are examples to tailor, not drop-in files — the README and reference
  both say so.
- Re-introducing any file-writing automation is a direction change and needs a new ADR.

## Alternatives considered

- **Fix the scaffolder** (gate the sync, scope the find, prompt per file): rejected —
  the failure mode is the blind-copy model itself, not its parameters.
- **Keep a manual sync helper script**: rejected — there are only ever a handful of
  thin `CLAUDE.md` files; writing them by hand in the same commit is safer.
