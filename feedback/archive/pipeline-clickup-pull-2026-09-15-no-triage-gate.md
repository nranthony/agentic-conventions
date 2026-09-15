# Skill feedback: clickup-pull — creates a work item without checking whether the task is already pulled, already done, or clear enough to act on

- From: pipeline (2026-09-15)
- Version: myconv 0.9.0 skill:7fae74312f6e
- Install mode: vendored container copy (seeded at `~/.claude/skills/myconv/` in the agent home)
- Invocation: none yet. The skill was read ahead of `/myconv:clickup-pull <task-id>`, to check the protocol against the two tasks currently at Ready for Agent.
- Artifact: skill
- Broke at: "## Create the item"
- Frequency: every run (structural: no step between "## Pull" and "## Create the item" can stop the write)
- Symptom: none-fit:no-triage-gate
- Verdict: generic. The skill assumes a task at the agent-ready status is actionable, pre-decided work that has not been started. Nothing in the repo shape makes that true. A board's status lags the repo whenever `/clickup-report` is skipped or someone writes a loose description. Both queued tasks in this repo break the assumption:
  1. **Already pulled.** One task was pulled into `work/` four weeks earlier and is partway through. It still shows the agent-ready status because the report step was never run. "## Re-pulling an existing item" covers what to do once an item is known to exist, but no step says to look for one. Finding it depends on the agent thinking to search, and missing it creates a duplicate numbered item.
  2. **Largely done, and asking for review rather than a build.** The second task's "Done when" names a metric the repo already ships (both extractors are registered, versioned and marked shipped in the repo's algorithm reference). The description's own comment line says the basic version is probably in place and asks for "a double check and a discussion of optimizing". It has no ClickUp comments. Followed as written, the skill would quote this verbatim into a new `spec.md` headed as pre-decided work. The skill's own premise, "a task already on a board is pre-decided almost by definition", is what fails here.
- Risk class: direction-setting. It changes what the skill decides: today a clean preflight always ends in a created item, and this proposes that a pull may legitimately end in no file.
- Workaround applied locally: no item was created. The agent searched live and by hand: the task ID across `work/`, `work/archive/`, the backlog index and git history, then the subject terms across source and docs. It reported the findings and stopped for the human to decide.

## Proposed edit
Insert a new section between "## Pull" and "## Create the item":

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

And under "## Create the item", replace:

> **default to `spec.md` for a pulled task and say so** — a task already on
> a board is pre-decided almost by definition.

with:

> **default to `spec.md` for a pulled task that passed the triage gate, and say so.**
> Where the human chose to pull anyway after a clarity stop, open it as the
> lifecycle's pre-decision file (`proposal.md` in this blueprint) instead, since the
> board status did not make it decided.
