# Test plan — ClickUp ↔ work/ sync

What still needs proving, what to build in ClickUp to prove it, and what each fixture
would catch. Ordered so the cheap prerequisites come first.

Legend: **[done]** already exercised · **[setup]** needs something built in ClickUp ·
**[run]** needs no new fixture, just a command.

---

## 0. Statuses — what is known, and what cannot be known from here

The six statuses exist in the Codebase Space, created in the ClickUp UI:

    To Do → Ready for Agent → Agent Working → In Progress → In Review → Complete

**This cannot be verified from inside the sandbox.** `myclickup` has no read path to a
Space's or List's status set: nothing in it requests `/list/{id}`, and `spaces` / `lists`
normalise their payloads to `{id, name}` before emitting. The only place a status appears
is inside an individual task.

That matters because it rules out the obvious shortcut. Sampling the statuses of existing
tasks shows which statuses are **in use**, never which exist — a status no task currently
sits in is invisible to that method. An earlier draft of this plan made exactly that
mistake and concluded two statuses were missing when they were not.

**Verified from task payloads (i.e. currently in use):** `to do` (open),
`ready for agent` (custom), `in review` (custom), `complete` (closed).
**Not yet observed on any task, which says nothing about existence:** `Agent Working`,
`In Progress`.

The only way to confirm a status from here is to **set it** — which is test W1. A
successful `update --status "Agent Working"` is the confirmation; there is no read-only
substitute.

> Upstream gap: this is the third missing read surface in `myclickup`, alongside no
> `workspaces` command and `spaces --json` dropping everything but id and name. A
> `myclickup statuses --list <path>` would close it, and the API already returns the array.

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
| **W8** [run] | Setting a status that does not exist fails loudly rather than silently no-opping | Use a deliberately fake name — `--status "Nonexistent Status"`. Runnable at any time; do **not** use a real status name for this |

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

1. **Run W1** on a fixture task — it doubles as the only available confirmation that
   `Agent Working` exists, since no read path can tell us (§0).
2. **Run R7** — no setup, closes the dependency-direction gap.
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
