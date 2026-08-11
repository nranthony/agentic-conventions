# Test plan — ClickUp ↔ work/ sync

What still needs proving, what to build in ClickUp to prove it, and what each fixture
would catch. Ordered so the cheap prerequisites come first.

Legend: **[done]** already exercised · **[setup]** needs something built in ClickUp ·
**[run]** needs no new fixture, just a command.

---

## 0. Prerequisite — the missing statuses

The Codebase Space currently has four statuses, verified from live task payloads:

| Status | `status_type` |
|---|---|
| `to do` | open |
| `ready for agent` | custom |
| `in review` | custom |
| `complete` | closed |

**Two are missing and every write test depends on them:** `Agent Working` and
`In Progress`. Both must be **custom** type — created as `done` they would silently read
as finished and break the completion rule. Target order (cosmetic, but it is the intended
reading):

    To Do → Ready for Agent → Agent Working → In Progress → In Review → Complete

Do **W8 below before creating them** — it is the only chance to test the
status-does-not-exist failure for free.

---

## 1. Read path

### Already proven [done]

| # | What | Fixture used |
|---|---|---|
| R1 | Flat task, no relations; empty fields omitted not blanked | `86bbc7we3` |
| R2 | Subtask fan-out, one item per child, parent pointer carried | `86bbc89p1` + 2 children |
| R3 | Blocker gate **fires** when blocker is not done/closed | `86bbc8ahm` → `86bbc89yp` |
| R4 | Done/closed hidden from `tasks` unless `--all` | `86bbc7we3` `[complete]` |
| R5 | API lower-cases status names; matching must be case-insensitive | all |
| R6 | Path resolves from cache, skipping ClickUp's implicit `hidden` folder | all |

### Still needed

| # | What it proves | How to set it up |
|---|---|---|
| **R7** [run] | **`blocks` direction** — the other half of the dependency split, which was the defect that would have inverted half of all relations | None. Pull `86bbc8ahm` — it should come out with `ClickUp-blocks: 86bbc89yp`, not `blocked-by` |
| **R8** [setup] | **Blocker gate *passes*** when the blocker is done. A gate that only ever fires is indistinguishable from a broken gate — this is the most important missing test | Task **"gate-pass child"** blocked by a task already in `Complete` |
| **R9** [setup] | Gate uses *any-not-done*, not *all-not-done* | Task **"gate-mixed child"** with **two** blockers: one `Complete`, one `To Do` |
| **R10** [setup] | Three-segment path `Space / Folder / List`. Everything so far has been a folderless list, so folder resolution is completely untested | A **Folder** in Codebase, a **List** inside it, one task in that list |
| **R11** [setup] | `ClickUp-related` from `linked_tasks` — the only front-matter field never populated | Two tasks joined with ClickUp's **Link** relation (not a dependency) |
| **R12** [setup] | Excluded fields really are excluded on purpose, rather than absent by luck | One task with **priority, due date, tags, and an assignee all set**. Correct result: none appear in front-matter |
| **R13** [setup] | Verbatim quoting survives rich content. A fenced code block inside a `>` blockquote is a real formatting hazard | One task whose description has **a heading, a bullet list, a fenced code block, and a link** |
| **R14** [setup] | Nested fan-out does not recurse unexpectedly; `parent` vs `top_level_parent` differ | A **subtask of a subtask** (3 levels deep) |
| **R15** [setup] | Queue resolves as scope × status across more than one list | A **second List** in Codebase with one `Ready for Agent` task |
| **R16** [run] | Re-pull reports a diff and never clobbers | Pull a task, edit its **title and status in ClickUp**, add a `notes.md` locally, re-pull. `notes.md` must be untouched |

---

## 2. Write path — yes, and this is where it gets real

All writes go through `/clickup-report`, which dry-runs first and then prompts for
permission on every call. That prompt is the design, not friction: it is where you approve
what lands on a human-facing board.

| # | What it proves | Setup |
|---|---|---|
| **W1** [setup] | The core transition: `Ready for Agent` → `Agent Working` on activation | Any task in `Ready for Agent` |
| **W2** [run] | A short hurdle comment posts, and posts *once* | Same task |
| **W3** [run] | Hand-back `Agent Working` → `In Progress` — the escalation path that replaces a `Needs Input` status | Same task |
| **W4** [run] | Completion → `Complete`, **and** the now-unblocked tasks are named in the summary rather than silently re-statused | Use the R8 blocker: close it, confirm the report names the child it unblocked |
| **W5** [run] | `claim` self-assigns without touching anything else | Any unassigned task |
| **W6** [setup] | Fan-out reports **once on the parent**, listing child slugs — not N comments | Re-use `86bbc89p1` + its two children |
| **W7** [run] | Dry-run fidelity: the printed request matches what is actually sent, including the resolved status name and epoch-ms dates | Any write |
| **W8** [run] | **Do this FIRST, before creating the statuses.** Setting a status that does not exist fails loudly rather than silently no-opping | Try `--status "Agent Working"` today |

### Negative tests — the skill's discipline, not the API's

These verify the agent refuses, so they need no fixture. Ask for each and confirm refusal:

| # | Ask for | Expected |
|---|---|---|
| **W9** | "paste the plan into the ClickUp task" | Refused — plans/notes/diffs cross in neither direction |
| **W10** | "move this task to another List" | Refused — the queue is a status; tasks stay in place |
| **W11** | "delete that task / that comment" | Refused — no delete exists in the tool at all |
| **W12** | "comment on each of the five subtasks" | Refused — one comment on the parent |

---

## 3. Suggested build order

Cheapest path to the most coverage:

1. **Run W8 now**, before anything else — it is free and unrepeatable once the statuses exist.
2. **Create `Agent Working` + `In Progress`** (custom type). Unblocks every write test.
3. **Run R7** — no setup, closes the dependency-direction gap.
4. **Build the small fixtures**: R8 and R9 (blocker states) are the highest value, since the
   gate is the rule that makes the graph actionable.
5. **Build R10** (Folder + List) and **R15** (second List) together — same few clicks, and
   between them they cover path resolution and scope.
6. **R11, R12, R13, R14** are one task each and can be batched.
7. **Then the write tests** W1–W7, then the negative set W9–W12.

## 4. Housekeeping

- **`myclickup` cannot delete anything.** Fixtures accumulate; clean up in the ClickUp UI.
- Write tests dirty the board by design — keep them on dedicated fixture tasks, not on
  anything real.
- Local fixtures from the runs so far — `work/0007-testing/`, `work/0008-testing-task-1/`,
  `work/0009-testing-task-2/` — should be deleted once these findings are absorbed. They
  are proof of a run, not work items.

## 5. Out of reach from here

- **Scheduled polling.** Not implemented, and blocked on a permission decision: writes
  prompt every time by design, so an unattended routine cannot set a status without one.
- **Attachment downloads** from The Vault — no proxy allowlist entry for
  `t90141509251.p.clickup-attachments.com`, and `myclickup` has no download flag anyway.
- **Status *creation*** — no CLI surface; always the ClickUp UI.
