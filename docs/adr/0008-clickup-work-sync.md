# ADR-0008: ClickUp and work/ are two projections of one item, synced partially

- Status: Accepted
- Date: 2026-08-11
- Deciders: nranthony + agent

## Context

The blueprint forced a false choice. `reference/agentic_native_repo_scaffold.md` said:
*"If in-flight work is tracked outside the repo (issues, ClickUp, etc.), skip `work/`
entirely."* That assumes a tracker and `work/` answer the same question, so you pick one.

They do not. The split is by **audience**, not by item:

| | ClickUp | `work/NNNN-slug/` |
|---|---|---|
| Answers | what to do, in what order, how it connects | what to load to do it well |
| Audience | human, at a glance, mobile, shareable | agent, at depth |
| Holds | non-code work, scheduling, dependencies | ADR links, spec, plan, notes |
| Cost of extra prose | **high** — it is a visual surface | low — depth is the point |

Both are wanted at once. The failure mode to avoid is the obvious one: mirroring bodies
between them, which destroys ClickUp's glanceability and creates two sources of truth.

Two facts shaped the answer. `conventions/beads/ADOPTION.md` §3 already recorded the same
model for a different tool — *"Keep (backlog of record) … pull items in on activation;
cross-link URLs both ways"*. And `myclickup`'s entire write vocabulary is `update`,
`comment`, `claim`, `tag`, `untag` with **no delete**, with reads allow-listed and writes
prompting every time: the asymmetry was already in the tooling, undocumented.

## Decision

**ClickUp is the backlog of record; `work/NNNN-slug/` is the agent's reference bundle.
They are two projections of one item, linked by an optional pointer and synced partially
and asymmetrically.**

1. **ClickUp → `work/`** — identity and intent, pulled selectively on activation.
   **`work/` → ClickUp** — status transitions and exception comments only.
   **Neither direction** — plans, notes, specs, diffs, file paths, ADR bodies.

2. **The link is a pointer, never a naming scheme.** `work/` keeps ADR-0006 numbering
   unchanged; ClickUp identity lives in the item's front-matter. The mapping is not 1:1
   (one task → N items from subtasks; items with no task; tasks with no item) and the
   pointer is optional in both directions.

3. **Front-matter is a timestamped snapshot, not a mirror.** It carries only what changes
   agent behaviour or is needed to write back — identity, path, parent, and the dependency
   graph. `due`, `priority`, `tags`, assignee and description are excluded: they change no
   behaviour and go stale silently. Relations never appear as bare IDs; a blocker that is
   not `done`/`closed` **stops the work**, and that gate re-reads live rather than trusting
   the snapshot.

4. **Field ownership is fixed.** ClickUp owns existence, title, priority, due date,
   parent/child, assignee, tags. `work/` owns the plan, notes, and decision trail. Status
   is the only shared field: `work/` proposes a transition, ClickUp is authoritative once
   written. Re-hydration appends or reports a diff — it never clobbers `notes.md`.

5. **Two statuses are added** to the standard set, both `custom` type:
   `To Do → Ready for Agent → Agent Working → In Progress → In Review → Complete`.
   `Agent Working` means an agent has the item in hand — distinct from a human being
   mid-task. No separate escalation status is needed, because `In Progress` already is
   one: `Agent Working → In Progress` is the hand-back. Completion is judged by
   `status_type` (`done`/`closed`), never by status name.

6. **The queue is a status, not a List** — `Ready for Agent` travels with the task,
   triggers ClickUp automations, and leaves the task in the project context that gives it
   meaning. A saved view gives the board without moving anything. The queue resolves as
   **scope × status**: `[work_sync].scope` bounds which lists are scanned.

7. **Configuration lives in `.myclickup.toml`.** `workspace_id` is the API boundary
   (required, singular) — *not* a scope. Repo scope, queue, WIP limit and the
   semantic-role → status-name map live in `[work_sync]` and `[statuses]`, which
   `myclickup` ignores. **The template ships `workspace_id` empty**: an empty pin falls
   back with a warning, a valid-but-wrong pin resolves silently against another
   workspace's board.

8. **Sync is human-invoked.** `/clickup-pull` (read-only against ClickUp) and
   `/clickup-report` (`--dry-run` first, always). Scheduled polling is the agreed future
   shape — poll, never webhook, since the sandbox has no inbound route — but is
   deliberately not implemented.

## Consequences

- The blueprint's "skip `work/` entirely" line is replaced; a repo may now run both, and
  the provenance chain gains an external-tracker link.
- ClickUp stays readable. Nothing an agent writes there is longer than a status change or
  a short comment, which is the property that made ClickUp worth keeping.
- The dependency graph becomes locally actionable: blockers gate work instead of decorating
  a header.
- `.myclickup.toml` gains an opt-in template. A repo with no tracker link never grows it.
- **The two skills ship with the plugin**, mirrored into `templates/.claude/skills/` and
  `plugins/myconv/skills/` alongside `make-plan` and `wrap-up`, with the justfile's
  `sync-plugin`, `check-plugin-sync` and `check-skill-mirrors` targets extended to cover
  them. The `myclickup` dependency is not a reason to withhold them: this repo's consumers
  are the author's own repos (README: *"how my repos are set up"*), where the CLI is baked
  into the same sandbox image. Withholding them would mean hand-installing into the
  majority to spare the minority. Both skills therefore **preflight on the CLI's presence
  and on `.myclickup.toml`**, and stop with a plain message rather than failing obscurely
  in the repos that lack either. Their `description` names the `.myclickup.toml`
  requirement so they do not auto-trigger where there is no tracker link.
- Because they ship inside a plugin, the skills **cite ADR-0008 without linking it** — an
  installed plugin cannot read outside its own payload, so a relative path out of it
  resolves nowhere. This is the same defect already fixed once in the bundled blueprint.
- **Two statuses must be created by hand in ClickUp** before any of this runs. Custom
  statuses are per-Space and no CLI can define them — a one-off human step, not a
  recurring dependency.
- Unattended polling stays blocked on a permission decision: `myclickup` writes prompt
  every time by design, and that is a choice to make deliberately rather than route around.
- **Unproven past a handful of items.** The not-1:1 cases and the subtask fan-out are
  reasoned, not observed. Statuses are cheap to rename; the front-matter schema is the
  expensive part to change later, so it ships minimal.
- Beads is deliberately not reconciled here. `ADOPTION.md` §3 retires plan files into `bd`
  while ADR-0006 makes `work/` the single in-flight pipeline — an existing tension this
  sits on top of. Beads is not initialised (`cv` reserved, never run) and adoption
  probability is currently low. If it later lands as the execution ledger, the chain
  becomes ClickUp → bd → `work/` and this ADR needs superseding. Building both bridges now
  would be the more expensive mistake.

## Alternatives considered

- **Full bidirectional mirroring of body content.** Rejected — destroys glanceability, and
  every published account of tracker↔agent integration names source-of-truth ambiguity and
  stale context as the failure mode.
- **Tracker-only (drop `work/`)** — the previous blueprint line. Rejected: leaves the
  agent's reference bundle homeless, and ClickUp is a poor place to read a plan.
- **`work/`-only (ignore ClickUp).** Rejected — loses ordering, the bigger picture,
  non-code items, and the shareable human view.
- **Folder names carrying the task ID** (`work/CU-86abc123-slug/`). Rejected — breaks
  ADR-0006's numbering invariant and cannot express the not-1:1 cases.
- **A dedicated `Agent Queue` List as the bucket.** Rejected — moving a task out of its
  home list destroys the context that is the reason ClickUp is in this design at all.
- **A gitignored `.clickup/` sync store.** Rejected — that is `.cache/myclickup/`, which
  already exists and is already specified (myclickup ADR-0004).
- **A real workspace ID as the template default.** Rejected — see Decision 7. It converts
  a loud failure into a silent one, and this repo has already shipped that class of bug
  once in `templates/CODEOWNERS`.
- **`Needs Input` as a sixth status.** Rejected as redundant — `In Progress` already means
  a human has it.
