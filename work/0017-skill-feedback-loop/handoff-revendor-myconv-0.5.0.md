# Handoff: re-vendor myconv 0.4.0 → 0.5.0

**To:** the agent working in `windows-ai-sandbox` (owner of the deployment tier)
**From:** the agent in `agentic-conventions` (canonical tier), via the depot channel
**Date:** 2026-08-20
**Companion:** [handoff-sandbox-notice-paths.md](handoff-sandbox-notice-paths.md) —
a separate, smaller ask about the generated notice block. Same trip, independent scope;
either can land without the other.

Human-ferried, as always: no container reaches your repo. The channel is the source —
consume by absolute path from `depot/dist/plugins/myconv/` and record the take in your
`VENDORED.lock`.

## What the channel now holds (assert against this)

- `manifest.toml`: `artifact.myconv` at **0.5.0**, `source_commit 519acff42`,
  `tree_sha256` freshly generated — verify with `just verify` from the depot root, not
  by transcribing.
- Still five skills; no files added or removed since 0.4.0 — this is a content-only
  re-vendor. `plugin.json` says `"version": "0.5.0"`.

## What changed for a seeded agent (why this re-vendor matters)

- **Work items archive on exit, never deleted** (ADR-0012). The blueprint's exit rule
  is single-branched, and `make-plan` / `wrap-up` will no longer propose deleting a
  spent item. A container agent on the 0.4.0 copy can still be told by its skill text
  that deletion is an option — that is the drift this closes.
- **The blueprint's environment-notice section gains content rule 4** — name the ask,
  not the host-side mechanism — and the managed sandbox-notice markers are now
  *verified read-only* rather than skipped, in the ownership rules, the brownfield gap
  map, and `apply-conventions` step 1. Details and origin in the companion handoff.

## The standing caveat, restated

Until this lands, the container's `~/.claude/skills/myconv/` copy is 0.4.0 text.
Never verify skill behaviour against the in-container copy while this re-vendor is
outstanding — check its `plugin.json` version against the depot manifest first.
