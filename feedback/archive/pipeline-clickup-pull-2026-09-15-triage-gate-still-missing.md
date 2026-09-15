# Skill feedback: clickup-pull — follow-up: 0.10.0 added live queue discovery but still has no triage gate, so discovery now leads straight to creating items for tasks that are already pulled or already done

- From: pipeline (2026-09-15)
- Version: myconv 0.10.0 skill:8bffa2c22678
- Install mode: vendored container copy (seeded at `~/.claude/skills/myconv/` in the agent home)
- Invocation: `/myconv:clickup-pull` with no task ID. The queue was found by the new "No task ID given?" step, then both matches were read with `task` / `comments --live`.
- Artifact: skill
- Broke at: "## Create the item" (reached from the new "No task ID given?" paragraph under "## Pull")
- Frequency: every run (structural: no step between "## Pull" and "## Create the item" can stop the write)
- Symptom: none-fit:no-triage-gate (same slug as the earlier report, so the two group together)
- Verdict: generic. This follows up `pipeline-clickup-pull-2026-09-15-no-triage-gate.md`. Its companion, `pipeline-clickup-pull-2026-09-15-queue-discovery-not-live.md`, landed in 0.10.0 almost as proposed, and the discovery step works. The triage gate did not land: "## Create the item" still reads "default to `spec.md` for a pulled task … a task already on a board is pre-decided almost by definition". Landing one without the other makes the gap bigger. Discovery ends with "Present what matched and take one task ID at a time — everything below runs per task", and "everything below" is Pull → Create. So every board-stale task that discovery finds now leads directly to a new file.
  The re-run on 0.10.0 found the same two tasks, both unchanged on the board since the first report:
  1. **Already pulled.** One task has had a `work/` item with spec, plan and notes since four weeks before the report. Its board status still says agent-ready because the report step was never run. Only a manual ID search sends it to "## Re-pulling an existing item" instead of a duplicate number.
  2. **Already built, and asking for review.** For the second task, both requested metrics exist, are registered and versioned, and are marked shipped in the repo's algorithm reference. Two things differ from the task: the method (the rate comes from amplitude, not intervals), and it is not in the default live chain. The description asks for "a double check and a discussion of optimizing". As written, the skill would still open this as a pre-decided `spec.md`.
- Risk class: direction-setting (unchanged). If the earlier proposal is waiting in the ADR-first lane, treat this as the second occurrence, not as a new request. Because 0.10.0 shipped discovery without the gate, this has become more urgent.
- Workaround applied locally: again, no item was created. The agent searched both task IDs by hand across `work/`, `work/archive/`, the backlog index and git history, then searched the second task's subject across source, docs, tests and validation evidence. It reported "already pulled" for one and "largely implemented; clarity stop" for the other, and stopped for the human to decide.

## Proposed edit
This is the same edit as the earlier report, re-anchored to 0.10.0. In "## Pull", change the last sentence of the "No task ID given?" paragraph:

> Present what matched and take one task ID at a time — everything below runs per task.

to:

> Present what matched and take one task ID at a time — everything below runs per task,
> and the triage gate decides whether a task gets a file at all.

Insert this new section between "## Pull" and "## Create the item":

> ## Triage gate — before any file is written
>
> A task at the agent-ready status is a claim about the board, not about the repo.
> Check it against the repo before creating anything. **A stop at any step writes
> no file**: report what you found and let the human choose (pull anyway, comment on
> the task to clarify, or close it on the board).
>
> 1. **Already pulled?** Search `work/`, `work/archive/` (or the repo's equivalents),
>    the repo's backlog index, and git history for the task ID and URL. A match goes
>    to "## Re-pulling an existing item", never to a new number. Name the paths you
>    searched even when nothing matched.
> 2. **Already done?** Search source, docs and history for the task's subject, using
>    its title and any "Done when" / acceptance terms. If the deliverable appears to
>    exist, stop and report the evidence (file and symbol, doc status line, commit),
>    including any gap between what exists and what the task names.
> 3. **Clear enough to act on?** Read the description *and* the comments pulled
>    above. Proceed only when together they name a deliverable or a checkable done
>    condition. Stop on hedged or open-ended asks ("I think this is in place",
>    "double check", "discuss", "look into"), on a description that only points
>    somewhere the agent cannot read (a share link, an unreachable doc), or on an
>    empty description with no scope in the thread. Suggest the clarifying comment
>    rather than writing one: this skill never writes to ClickUp.
>
> Record the gate's result in the handoff either way ("checked: not pulled, no
> existing implementation found, done-condition stated"), so a pass reads differently
> from a gate that never ran.

Under "## Create the item", replace:

> **default to `spec.md` for a pulled task and say so** — a task already on
> a board is pre-decided almost by definition.

with:

> **default to `spec.md` for a pulled task that passed the triage gate, and say so.**
> Where the human chose to pull anyway after a clarity stop, open it as the
> lifecycle's pre-decision file (`proposal.md` in this blueprint) instead, since the
> board status did not make it decided.

Under "## Then", add:

> When the gate stopped on an already-pulled task whose board status never moved, name
> `/clickup-report <item>` as the fix for the board. The next discovery run will find
> that task again until its status changes.
