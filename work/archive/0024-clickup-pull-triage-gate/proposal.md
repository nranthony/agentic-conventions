# Proposal: a triage gate in `/myconv:clickup-pull` — a pull may legitimately end with no file

- Status: Accepted → [ADR-0019](../../../docs/adr/0019-a-pull-may-end-with-no-file.md) — signed
  by the owner in-session, 2026-09-15, as proposed, on `pipeline`'s second report
  (`feedback/archive/pipeline-clickup-pull-2026-09-15-triage-gate-still-missing.md`, against
  0.10.0). Applied in myconv 0.12.0, with the report's two additions: the discovery sentence
  names the gate, and `## Then` names `/clickup-report <item>` for a stale board status.
- Author: agent (triage of `pipeline`'s report of 2026-09-15), presented under
  [ADR-0013](../../../docs/adr/0013-skill-feedback-channel.md) §4

## Summary

`pipeline` reports that `/myconv:clickup-pull` cannot decline to pull. Between `## Pull`
and `## Create the item` there is no step that can stop the write, so a task the board
says is ready but the repo says is already pulled, already done, or not yet decided still
ends as a numbered item on disk. The report proposes a **triage gate**: three checks, any
of which may stop the run, where a stop writes no file and reports instead.

It is classed **direction-setting** by its author, and triage agrees. Nothing here is
applied. Under the feedback channel's own rule (ADR-0013 §4) a triager presents a
direction-setting proposal with its evidence and its assessment; the owner discusses and
signs, and only then does it become an ADR. Reporter, triager and signer are three roles,
and the last is not an agent.

## Motivation

### The claims, checked against the shipped text

The report ran against myconv 0.9.0 (`skill:7fae74312f6e`). All three claims hold against
the canonical `.claude/skills/clickup-pull/SKILL.md` as it stands today:

| Claim | Verified |
|---|---|
| Nothing between `## Pull` and `## Create the item` can stop the write | Yes. `## Pull` reads the task and comments; `## Create the item` opens with the path to write. There is no branch in between, and no stop anywhere in the skill except the preflight ones |
| `## Re-pulling an existing item` says what to do once an item is known to exist, but nothing says to look for one | Yes. The only instruction that reads `work/` is "`NNNN` is the next free number across active **and** archived items" — which finds the next number, not the task ID. Whether the existing item is found depends on the agent thinking to search |
| The skill's premise is that a board task is pre-decided | Yes, stated: "**default to `spec.md` for a pulled task and say so** — a task already on a board is pre-decided almost by definition" |

### Why it is direction-setting, and why triage did not carve a piece off

The edit changes what the skill *decides*. Today a clean preflight always ends in a
created item; the proposal makes "no file written" a legitimate outcome, and retires a
stated premise of the skill.

The tempting move is to split it: the "already pulled?" search only routes to a branch
the skill already has (`## Re-pulling an existing item`), so it looks mechanical, while
"already done?" and "clear enough to act on?" invent a new stop. **Triage did not do
that.** ADR-0013 §3 says the reporter's risk class is a claim a triager may reclassify
*upward, never downward*. Carving a third of a direction-setting report out as mechanical
is a downward reclassification with extra steps, and the rule exists precisely so that a
report cannot be merged a piece at a time without the human seeing it. If the owner wants
the search step landed on its own, that is a decision to take here, not a classification
to discover.

### The recurrence signal

`feedback/README.md` asks for the `symptom` column to be grepped first. This symptom
(`none-fit:no-triage-gate`) is new, so by the letter it is an anecdote. By shape it is
not: this is the **second** direction-setting report against `clickup-pull`, and both
have the same root — *the skill trusted the board over the repo*. The first (`legal`,
2026-08-25, `assumed-repo-shape`) became ADR-0014, "repo content policy overrides skill
writes". That record settled what a pulled item may *contain*; this one asks whether a
pulled item should exist at all. Same direction, next question.

It also sits squarely with ADR-0015 (skills conform to the repo they run in) — with one
tension worth the owner's attention, below.

## Proposal

Insert a gate between `## Pull` and `## Create the item`. The report's own wording is in
`feedback/archive/pipeline-clickup-pull-2026-09-15-no-triage-gate.md`; in substance:

1. **Already pulled?** Search `work/`, `work/archive/`, the repo's backlog index and git
   history for the task ID and URL. A match routes to `## Re-pulling an existing item`,
   never to a new number. Name the paths searched even when nothing matched.
2. **Already done?** Search source, docs and history for the task's subject and any
   "done when" terms. If the deliverable appears to exist, stop and report the evidence,
   including the gap between what exists and what the task names.
3. **Clear enough to act on?** Read description *and* comments together. Proceed only
   where they name a deliverable or a checkable done condition. Stop on hedged or
   open-ended asks, on a description that only points somewhere unreadable, or on an
   empty description with no scope in the thread.

A stop writes no file and reports; the human chooses (pull anyway, comment on the task,
or close it). The gate's result is recorded in the handoff either way, so a pass reads
differently from a gate that never ran. Where the human pulls anyway after a clarity
stop, the item opens as the lifecycle's pre-decision file (`proposal.md` here) rather
than `spec.md`.

**If accepted this needs an ADR** — the repo's rule is that a direction-setting change
gets one (`AGENTS.md`), and both direction-setting rows in the ledger cite one. The next
free number is **0019**. It is deliberately not written yet: ADR-0013 §4 puts the
signature after the discussion, and this repo has no Proposed-status ADR in eighteen
records — its pre-decision surface is this file (ADR-0006, proposals are work items).

## Open questions — the owner's call

1. **Does step 3 fight ADR-0015?** That record's posture, quoted in the skill, is that a
   missing piece is "a *state*, not an error: proceed on a stated basis, say what you
   assumed, and stop only where proceeding would be unsafe." A hedged task description is
   a state. The argument for stopping anyway is that the unsafe thing here is a written
   file: a `spec.md` headed as pre-decided work, quoting "I think this is probably in
   place, let's discuss" verbatim, is a tracked claim that the work was decided. The
   argument against is that three stop conditions make a read-only skill refuse work
   fairly often, and the failure mode of an over-eager gate — "I could not tell, so I did
   nothing" — is invisible in exactly the way the feedback channel exists to fix.
2. **How much searching is proportionate?** Step 2 is an open-ended repo search on every
   pull. Cheap in a small repo, not in a large one, and its stop condition is a judgement
   ("appears to exist") rather than a check.
3. **Is step 1 separable?** See above — triage declined to decide this; the owner can.
4. **Does the `spec.md` default survive?** The report keeps it for tasks that pass the
   gate and swaps to `proposal.md` after a clarity stop. That is a smaller change than it
   looks: it makes the lifecycle's own pre-decision file the honest default whenever the
   board's status was the only evidence of a decision.

## Alternatives

- **Reject and leave the skill as is.** The workaround the reporter applied — search by
  hand, report, stop — is what a careful agent does anyway, and the skill already tells
  an agent to conform to the repo. Against: it did *not* work; the reporter deviated from
  the skill to get there and filed a report saying so, which is the channel working as
  designed, not evidence that the text was sufficient.
- **Land step 1 only** (the duplicate-item search), and leave the two judgement stops.
  This fixes the failure with an objective check and no new stop class: a match routes to
  a branch the skill already owns.
- **Make the gate advisory** — report all three findings, always create the item, never
  stop. Keeps today's guarantee that a pull produces something. Against: it writes the
  duplicate item anyway, which is the concrete harm.
- **Push it to `/clickup-report` instead**, letting the pull always write and the report
  step refuse to move a task whose item duplicates another. Against: the duplicate file
  is already on disk by then, and `/clickup-report`'s refusals are about board writes.
