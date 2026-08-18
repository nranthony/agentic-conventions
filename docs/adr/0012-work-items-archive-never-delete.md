# ADR-0012: Work items archive on exit; the delete option is withdrawn

- Status: Accepted
- Date: 2026-08-18
- Deciders: nranthony + agent (Opus 5)
- Amends: [ADR-0006](0006-proposals-are-work-items.md) — its exit-rule clause only. The
  single numbered pipeline that ADR established stands unchanged and it remains Accepted.
- Distilled from: `work/0019-archive-never-delete/plan.md`

## Context

The exit rule for a work item reached its current shape in two steps. The
plans-live-in-work decision (ADR-0003) set it as "delete or archive on merge", because a
stale spec left active poisons future agent context. The proposals-are-work-items decision
(ADR-0006) overturned the delete half for anything carrying a proposal — "distill, then
archive — never bare-delete" — because deleting a folder destroys the discussion record
that made the proposal tier worth having. But it kept one sentence of carve-out:

> Pure-implementation items with nothing durable may still be deleted.

That sentence is the source of every "or delete it" the blueprint ships. It appears three
times in the reference scaffold, twice in the templates, and once each in the planning and
wrap-up skills — and the apply-conventions skill, which is what a consumer repo actually
runs, inherits all of it as payload without ever mentioning deletion itself.

Three things are wrong with the carve-out:

- **It asks for an unverifiable judgment at the moment it is least available.** "Nothing
  durable remains" is not an observation about the folder, it is a prediction about future
  readers. The agent making the call is the one with the least distance from the work.
- **The two outcomes are not symmetric.** Archiving costs a directory entry in a tree
  nobody is required to read. A wrong delete costs the record permanently and silently.
  Git history is not the backstop it looks like: a short-lived implementation item is
  often opened, worked, and closed inside one thread, so there may be no commit holding it.
- **It punches holes in a sequence that promises not to have them.** Numbers are never
  reused, so a missing number is meaningful — and after a delete, unreadable. A reader who
  finds `0013` absent cannot tell whether it was deleted, never opened, or yielded to a
  concurrent session. That last one is not hypothetical: `work/0018` yielded `0017` two
  days ago and said so in writing precisely so the gap would stay legible.

The benefit being bought is tidiness. The price is an irreversible action taken on a guess.

## Decision

**A work item exits by archiving. Always.** The exit rule is now single-branched:
before an item closes, distil anything durable out — decision rationale into an ADR,
reference knowledge into `docs/` or a skill — then move the folder to `work/archive/`
(committed). There is no second branch, and no "unless nothing durable remains".

- **No skill may suggest deleting a work item.** This binds the shipped blueprint
  (`reference/`, `templates/`) and the shared skills alike, so a consumer repo that runs
  the apply-conventions skill receives one rule with one voice.
- **Scope is `work/NNNN-slug/` items only.** Every other deletion rule in the conventions
  stands untouched: the `inbox/` doorbell is still read-then-deleted once distilled,
  `work/plans/` is still gitignored scratch that never enters the tree, and the ClickUp
  write path still has no delete verb at all.
- **Numbers are still never reused**, and now a gap in the sequence can only mean a
  yielded or never-opened number — never a destroyed one.

## Consequences

- `work/archive/` grows without bound. That is the intended outcome, not a cost accepted
  reluctantly: an archived item is a few kilobytes of markdown, and the tier's whole value
  is that the trail from a line of code back to the reasoning that produced it stays
  walkable.
- Seven lines change across five files, plus this repo's own `work/README.md`. The
  apply-conventions skill body needs no edit — it never mentioned deletion.
- Consumers receive a changed rule, so this is a CHANGELOG entry and a version bump in
  both the plugin and marketplace manifests, not internal churn.
- **ADR-0006 keeps its Accepted status** and gains an "Amended by" pointer in its header.
  Flipping it to "Superseded by" would falsely retire the single-pipeline decision, which
  is untouched and still load-bearing. This follows the shape already used when the
  gloss-shorthand decision (ADR-0011) widened the gloss-before-cite decision (ADR-0010)
  without replacing it. The pointer is an added line, not a rewrite — the append-only rule
  is intact.
- The old wording survives inside `work/archive/` items and inside ADR-0003 and ADR-0006
  themselves. That is correct and deliberate: those are historical records, and the
  archived ones are explicitly not current intent.

## Alternatives considered

- **Keep the carve-out and add guidance on when it applies:** rejected. Any such guidance
  has to define "nothing durable", which is exactly the judgment that cannot be verified
  at exit time. It would add words without removing the failure.
- **Allow deletion but require a tombstone file recording the number and why:** rejected —
  a tombstone is an archived folder with fewer bytes and more mechanism. If the number has
  to stay explained, keep the thing that explains it.
- **Fix only the apply-conventions payload, leave the planning and wrap-up skills:**
  rejected. It is the narrower reading of the ask, but it ships two voices from one
  plugin, and name-based drift between skills is already an open complaint
  (`work/0014-wrap-up-generality`).
- **Delete on exit for everything, as originally written (ADR-0003):** noted for the
  record and still rejected on ADR-0006's original grounds.
