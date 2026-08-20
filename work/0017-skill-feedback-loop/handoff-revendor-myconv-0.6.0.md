# Handoff: re-vendor myconv 0.4.0 → 0.6.0

**To:** the agent working in `windows-ai-sandbox` (owner of the deployment tier)
**From:** the agent in `agentic-conventions` (canonical tier), via the depot channel
**Date:** 2026-08-20 (supersedes the 0.5.0 handoff written earlier the same day —
never delivered, so this one carries both releases in one trip)
**Companion:** [handoff-sandbox-notice-paths.md](handoff-sandbox-notice-paths.md) —
already landed (the regenerated notice dropped the host-only path); no action left.

Human-ferried, as always: no container reaches your repo. The channel is the source —
consume by absolute path from `depot/dist/plugins/myconv/` and record the take in your
`VENDORED.lock`.

## What the channel now holds (assert against this)

- `manifest.toml`: `artifact.myconv` at **0.6.0**, fresh `source_commit` and
  `tree_sha256` — verify with `just verify` from the depot root, not by transcribing.
- **Six skills now**, not five: `report-skill-feedback` is new. Every skill directory
  also gains a generated `VERSION` sidecar file — ship it; it is how a copy
  self-identifies. Your sync's `variants/`-stripping exclusion is untouched; nothing
  else about the tree shape changed.

## What changed for a seeded agent (why this re-vendor matters)

- **0.5.0 — work items archive on exit, never deleted** (ADR-0012), and the
  blueprint's environment-notice rules: name the ask, not the host-side mechanism;
  the managed notice markers are verified read-only rather than skipped.
- **0.6.0 — the feedback channel** (ADR-0013). `/myconv:report-skill-feedback` owns a
  report envelope; the other five skills tell a deviating agent to file before
  working around. **For your tier specifically:** an agent in a container that hits a
  wrong skill will now write a report file locally and name delivery as a
  human-ferried step — expect such files, and ferry them to the conventions repo's
  `inbox/`. The `VERSION` sidecars end the "which text is the container running"
  guesswork: `cat ~/.claude/skills/myconv/*/VERSION` answers it against the manifest.

## The standing caveat, restated

Until this lands, the container's copy is 0.4.0 text. Never verify skill behaviour
against the in-container copy while this re-vendor is outstanding — after it lands,
the sidecar makes that check trivial.
