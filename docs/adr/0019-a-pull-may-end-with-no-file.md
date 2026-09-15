# ADR-0019: A pull checks the task against the repo first, and may end with no file

- Status: **Accepted**
- Date: 2026-09-15
- Deciders: nranthony (owner, signed in-session on 2026-09-15, accepting the proposal as
  written) + agent
- Extends: ADR-0008 (ClickUp ↔ `work/` sync) and ADR-0014 (repo content policy overrides
  skill writes). Distilled from
  [work/archive/0024](../../work/archive/0024-clickup-pull-triage-gate/proposal.md).

## Context

`/myconv:clickup-pull` had no step between reading a task and writing its item that could
stop the write. It said so as a premise: "a task already on a board is pre-decided almost by
definition". A board's status lags the repo whenever `/clickup-report` is skipped or a task
is written loosely, and nothing in the skill looked.

`pipeline` reported it twice on 2026-09-15, against the same two queued tasks:

- **Against 0.9.0**, reading ahead of a pull. One task had been pulled into `work/` four
  weeks earlier and was partway through, its board status never moved; nothing told the
  agent to search for it, so a duplicate numbered item depended on the agent thinking to.
  The other asked for "a double check and a discussion of optimizing" of a metric the repo
  already ships; as written, the skill would have quoted that into a `spec.md` headed as
  decided work.
- **Against 0.10.0**, after live queue discovery shipped from that report's companion.
  Discovery ends "everything below runs per task", and everything below was Pull → Create.
  Shipping discovery without a gate made the gap wider: every board-stale task it finds
  now leads straight to a new file.

Both times the reporter deviated from the skill — searched by hand, reported, stopped — and
filed. This is the second direction-setting report on the skill with the same root: the
board's claim outranking the repo's state. The first became ADR-0014, which settled what a
pulled item may contain; this one settles whether it should exist.

## Decision

**1. A triage gate runs between `## Pull` and `## Create the item`**, per task, with three
checks. A stop at any of them writes no file: the skill reports what it found and the human
chooses — pull anyway, comment on the task to clarify, or close it on the board.

1. **Already pulled?** Search the repo's item directories (active and archived), any
   backlog index it keeps, and git history for the task ID and URL. A match routes to
   `## Re-pulling an existing item`, never to a new number.
2. **Already done?** Search source, docs and history for the task's subject. Where the
   deliverable appears to exist, stop with the evidence and the gap between what exists
   and what the task names.
3. **Clear enough to act on?** Description and comments together must name a deliverable
   or a checkable done condition. Hedged or open-ended asks, a description that only points
   somewhere unreadable, and an empty description with no scope in the thread all stop.

A search names the paths it checked even when nothing matched.

**2. The gate's result is recorded in the handoff either way**, so a pass reads differently
from a gate that never ran.

**3. `spec.md` stays the default only for a task that passed the gate.** Where the human
pulls anyway after a clarity stop, the item opens as the lifecycle's pre-decision file
(`proposal.md` in this blueprint): the board's status was the only evidence of a decision.

**4. An already-pulled task whose status never moved names `/clickup-report <item>`** as
the fix for the board, since discovery finds it again until the status changes.

## Consequences

- **"No file written" is a legitimate end of a pull.** A clean preflight no longer
  guarantees an item. The skill still never writes to ClickUp; a clarity stop suggests the
  comment rather than posting one.
- **This does not contradict ADR-0015.** That record's first rule allows a stop "where
  proceeding would be unsafe or would silently produce a wrong result". A `spec.md` headed
  as decided work for a task that asks to discuss is that wrong result, written into a
  tracked file.
- **The "already done?" search costs something on every pull**, more in a large repo, and
  its stop is a judgement ("appears to exist"), not a check. Accepted as proposed; the
  evidence requirement is what keeps the judgement reviewable. If it proves too eager, that
  arrives as feedback, by the channel built for it.
- **The discovery sentence says the gate decides**, so the per-task hand-off no longer
  reads as Pull → Create.

## Alternatives considered

Recorded in full in the proposal. In short:

- **Reject and rely on careful agents.** Rejected: the careful agent deviated from the
  skill to get there, twice.
- **Land only the "already pulled?" search.** An objective check with no new stop class.
  Not chosen: the second task would still become a decided `spec.md`.
- **An advisory gate that never stops.** Rejected: it writes the duplicate anyway, which is
  the concrete harm.
- **Refuse in `/clickup-report` instead.** Rejected: the duplicate is already on disk by
  then, and that skill's refusals are about board writes.
