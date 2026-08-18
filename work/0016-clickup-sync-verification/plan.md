# Plan: verify the ClickUp ↔ work/ sync against a live board

- Status: Open — not started. Needs roughly an hour at the ClickUp UI to build fixtures.
- Author: agent in `agentic-conventions`
- Opened: 2026-08-16, split out of `work/0006-clickup-work-sync/` when that item was
  archived. Pre-decided work, so it opens as a plan rather than a proposal.
- Decides nothing: the design is the board-sync decision (ADR-0008, Accepted 2026-08-11).
  This item only proves the implementation matches it.

## Why this is its own item

Everything in the archived item is done except live verification: the proposal was accepted
and distilled, the skills shipped, and the CLI-first rewrite moved mechanism into
`myclickup`. Keeping an eleven-fixture matrix open inside a finished item made it read as
in-flight work when it is really a backlog. This carries only what is still unproven.

The predecessor's own test plan is a record of the 0.2.0 era and is **not** current intent
— read this file, not that one.

## What is already proven

From two live pulls on 2026-08-11 (`work/archive/0006-clickup-work-sync/notes.md`):
flat-task pull with empty fields omitted rather than blanked (R1); subtask fan-out, one
item per child carrying its parent pointer (R2); the blocker gate **firing** on a
not-done blocker (R3); done/closed hidden from `tasks` without `--all` (R4); status names
coming back lower-cased, so matching must be case-insensitive (R5); path resolution from
the cache, skipping ClickUp's implicit `hidden` folder (R6).

Those runs found five defects, all fixed in the skills before this item existed.

## Statuses — what changed since the old plan

The archived plan opened by arguing that a list's status set is unreadable from here, so
setting a status was the only way to confirm one existed. **That is no longer true.**
`myclickup statuses --list <path>` reads the set directly (0.3.0+, confirmed against the
0.6.0 binary in-container, which matches `manifest.toml`). Two consequences:

- A status no task currently sits in is visible now, so the old sampling trap is gone.
- The two agent statuses (`Ready for Agent`, `Agent Working`) exist in the Codebase /
  Agentic Conventions list as of 2026-08-12. The write path is untested, not blocked.

Status *creation* is still a ClickUp UI step — no CLI surface, and none is wanted.

## Read path — still needed

| # | What it proves | Setup |
|---|---|---|
| **R7** [run] | **`blocks` direction** — the other half of the dependency split, and the defect that would have inverted every relation | None. Pull `86bbc8ahm`; it must come out with `ClickUp-blocks: 86bbc89yp`, not `blocked-by` |
| **R8** [setup] | **The blocker gate *passes*** when the blocker is done. A gate that only ever fires is indistinguishable from a broken gate — the highest-value missing test | A task blocked by one already in `Complete` |
| **R9** [setup] | The gate is *any-not-done*, not *all-not-done* | A task with **two** blockers: one `Complete`, one `To Do` |
| **R10** [setup] | Three-segment `Space / Folder / List` paths. Every fixture so far was a folderless list, so folder resolution is wholly untested | A Folder in Codebase, a List inside it, one task in it |
| **R11** [setup] | `ClickUp-related` from `linked_tasks` — the only front-matter field never populated | Two tasks joined by ClickUp's **Link** relation, not a dependency |
| **R12** [setup] | Excluded fields are excluded *on purpose* rather than absent by luck | One task with priority, due date, tags and an assignee all set. Correct result: none reach front-matter |
| **R13** [setup] | Verbatim quoting survives rich content — a fenced code block inside a `>` blockquote is a real hazard | One task whose description has a heading, a bullet list, a fenced block and a link |
| **R14** [setup] | Fan-out does not recurse unexpectedly; `parent` and `top_level_parent` differ | A subtask of a subtask, three levels deep |
| **R15** [setup] | The queue resolves as scope × status across more than one list | A second List in Codebase with one `Ready for Agent` task |
| **R16** [run] | Re-pull reports a diff and never clobbers | Pull a task, change its title and status in ClickUp, add a local `notes.md`, re-pull. The `notes.md` must be untouched |

## Write path — still needed

All writes go through `/clickup-report`, which dry-runs first and prompts on every call.
The prompt is the design: it is where a human approves what lands on a human-facing board.

| # | What it proves | Setup |
|---|---|---|
| **W1** [run] | The core transition on activation: `Ready for Agent` → `Agent Working` | Any task in `Ready for Agent` |
| **W2** [run] | A short hurdle comment posts, and posts *once* | Same task |
| **W3** [run] | Hand-back `Agent Working` → `In Progress`, the escalation path that replaces a `Needs Input` status | Same task |
| **W4** [run] | Completion → `Complete`, **and** newly-unblocked tasks are named in the summary rather than silently re-statused | Close the R8 blocker; confirm the report names the child it unblocked |
| **W5** [run] | `claim` self-assigns and touches nothing else | Any unassigned task |
| **W6** [setup] | Fan-out reports **once on the parent**, listing child slugs — not N comments | `86bbc89p1` and its two children |
| **W7** [run] | Dry-run fidelity: the printed request matches what is sent, resolved status name and epoch-ms dates included | Any write |
| **W8** [run] | A status that does not exist fails loudly instead of silently no-opping | A deliberately fake `--status "Nonexistent Status"`. Never a real status name |

### Negative tests — the skill's discipline, not the API's

No fixture needed; ask for each and confirm the refusal.

| # | Ask for | Expected |
|---|---|---|
| **W9** | "paste the plan into the ClickUp task" | Refused — plans, notes and diffs cross in neither direction |
| **W10** | "move this task to another List" | Refused — the queue is a status, so tasks stay in place. Note the tool *can* do it: `myclickup move` exists as of 0.6.0, so this tests policy, not a missing verb |
| **W11** | "delete that task / that comment" | Refused — 0.6.0 has no `delete` or `rm` command at all, and both are pre-emptively denied in the channel's permission data |
| **W12** | "comment on each of the five subtasks" | Refused — one comment on the parent |

## Order

1. **W1** — the activation transition, and the cheapest write to run.
2. **R7** — no setup, closes the dependency-direction gap.
3. **R8 and R9** — the gate states, highest value of the fixtures.
4. **R10 and R15** together — the same few clicks cover folder resolution and scope.
5. **R11–R14** — one task each, batchable.
6. The remaining writes **W2–W7**, then the negative set **W9–W12**.

## Housekeeping

- `myclickup` cannot delete anything, so fixtures accumulate — clean up in the ClickUp UI.
- Write tests dirty the board by design. Keep them on dedicated fixture tasks.
- **Fixture items do not become work items.** The three from the 2026-08-11 runs were
  deleted on 2026-08-16 once their findings were absorbed; do the same here. A pulled
  fixture is proof of a run.

## Out of reach

- **Scheduled polling** — not implemented, and blocked on a policy decision: writes prompt
  every time by design, so an unattended routine cannot set a status without one.
- **Attachment downloads** from The Vault — no proxy allowlist entry for the attachments
  host, `t90141509251.p.clickup-attachments.com`. Corrected 2026-08-17: the CLI *does*
  have the flag (`attachments <id> --download --dir <path>`, host-restricted and
  never-overwriting — myclickup `docs/adr/0010-attachment-downloads.md`, shipped
  2026-08-12). The allowlist entry is the only thing still missing, and it is a human
  step in the sandbox repo.

## Exit

Every row above either passes, or is struck with a recorded reason. Defects found go to the
skills (policy) or to `myclickup` (mechanism), per the split the CLI-first rewrite settled.
Anything durable that the runs teach lands in ADR-0008's lineage or the skill text — then
this item archives.
