# Proposal: Partial sync between ClickUp and work/

- Status: Accepted → [ADR-0008](../../docs/adr/0008-clickup-work-sync.md)
- Author: nranthony + agent
- Date: 2026-08-11

## Summary

ClickUp and `work/NNNN-slug/` are **two projections of one item**, not competing homes
for it. ClickUp answers *what needs doing, in what order, and how it connects to the
bigger picture* — for a human, at a glance, including non-code work. `work/` answers
*what an agent must load to do this well* — ADR links, spec, plan, running notes.

This proposes a deliberately **partial and asymmetric** sync between them:

- **ClickUp → `work/`**: identity and intent, pulled selectively when *you* activate an
  item (one task, or one task's subtasks fanned out to several items).
- **`work/` → ClickUp**: status transitions and exception comments only.
- **Neither direction**: plans, notes, specs, diffs, file paths, ADR bodies.

The third bullet is the load-bearing one. ClickUp's value is being low-cognitive-load;
pushing markdown into it destroys the only thing it is better at than the repo.

## Motivation

### The blueprint currently forces a false choice

`reference/agentic_native_repo_scaffold.md:77` reads:

> If in-flight work is tracked outside the repo (issues, ClickUp, etc.), skip `work/` entirely.

That assumes the tracker and `work/` answer the same question, so you pick one. In
practice both are wanted at once, and the split is by *audience*, not by *item*:

| | ClickUp | `work/NNNN-slug/` |
|---|---|---|
| Answers | what to do, in what order, how it connects | what to load to do it well |
| Audience | human, at a glance, mobile, shareable | agent, at depth |
| Holds | non-code work, scheduling, dependencies, the bigger picture | ADR links, spec, plan, notes |
| Cost of extra prose | **high** — it is a visual surface | low — depth is the point |

### The direction is already half-decided here

`conventions/beads/ADOPTION.md` §3 already records the same model for a different tool:

> **GitHub Issues / Linear / etc.** — Keep (**backlog of record**) — Human-facing backlog
> + stakeholder view. **Pull items into bd epics on activation; cross-link URLs both ways.**

"Pull on activation" and "cross-link both ways" are exactly this proposal. What is new is
naming `work/` as the pull target and specifying what flows *back*. Beads is explicitly
**out of scope** here (see Open questions).

### The tool already has the right shape

`myclickup`'s entire write vocabulary is `create`, `update`, `claim`, `comment`, `tag`,
`untag` — **and no delete**. Its sandbox profile allow-lists 13 read commands unprompted
and prompts on every write. "Status, comment, claim" *is* the tool surface. This proposal
documents an asymmetry the tooling already enforces rather than inventing one.

## Proposal

### 1. Prerequisites (must land before any pull)

- **`.cache/` in `.gitignore`** — both this repo's and `templates/.gitignore`. **Done.**
  Cache writes happen on *any* read command that misses (`cli/common.py:41-43`), not just
  `sync`, and cached space/list **names** may carry customer identifiers (myclickup
  ADR-0005).
- **`.myclickup.toml` at repo root**, pinning the workspace and mapping statuses (§4.1).
  `myclickup whoami` currently reports *"token sees 4 workspaces; using the first (id
  9017949595, 'FluidMomenta')"* — every command silently targets the wrong workspace until
  this is pinned. IDs are config, not secrets; tokens never go in this file.
  **Blocked on: which workspace, and which Space carries the queue.**
- **The two new statuses created in ClickUp** (§4). A human UI step — custom statuses are
  per-Space, `myclickup` has no status-definition command, and ClickUp will reject any
  attempt to set a status that does not exist in the task's home location.

### 1.1 Workspace pin vs. repo scope — two different things

**`workspace_id` is not a scope setting. It is the API boundary.** Every ClickUp API call
is workspace-scoped, and one token can see several workspaces (this one sees four). It is
a *required parameter*, singular and mandatory, answering "whose board" — never "which
part of the board".

**Repo scope is the separate question**, and `myclickup` cannot currently express it:
its config supports `workspace_id` and `list_id` and **has no `space_id`**. That is fine —
scope is a sync-convention concern, not a `myclickup` concern, so it lives in the
`[work_sync]` table `myclickup` ignores. The full file:

```toml
# Non-secret pins (myclickup ADR-0005): committed by design. Never a token.
workspace_id = "..."          # myclickup reads this — REQUIRED, the API boundary
list_id      = "..."          # myclickup reads this — optional default for `create`

[work_sync]                   # skills only; myclickup ignores unknown tables
scope     = ["Build/Action Items", "Build/Bugs"]  # a subsection…
# scope   = ["Build"]                             # …or a whole Space
# scope   = []                                    # …or the whole workspace
queue     = "Build/Action Items"
wip_limit = 3

[statuses]
agent_ready   = "Ready for Agent"
agent_working = "Agent Working"
human_active  = "In Progress"
review        = "In Review"
```

This also resolves an ambiguity in §6: **the queue is scope × status.** `scope` says which
lists to scan; `agent_ready` says which tasks within them are queued. The bucket stays a
status (tasks never move lists), and `scope` is what keeps the scan bounded.

### 1.2 Two copies of this file, and only one carries real IDs

- **This repo's `.myclickup.toml`** — real values, committed. IDs are configuration, not
  secrets (myclickup ADR-0005). This is the dogfooding copy, and it is what the open
  workspace question blocks.
- **`templates/.myclickup.toml`** — ships to other repos through
  `/myconv:apply-conventions`, and **must stay generic**: AGENTS.md requires templates to
  carry "no real owners, tokens, or repo-specific paths".

**The template ships `workspace_id` empty, not defaulted.** A real ID used as a "sensible
default" is the worst of the three states, because of an asymmetry in how `myclickup`
fails (`client.py:127-145`):

| Template ships | Adopting repo forgets to change it | Failure mode |
|---|---|---|
| **empty** | falls back to `teams[0]` **with a warning** naming the workspace | loud — **chosen** |
| a real ID | resolves cleanly to *someone else's board* | **silent** |

The docstring for that fallback calls it "the wrong-workspace trap the pin exists to
close". Shipping a default ID would re-open the trap for every adopting repo, and this
repo has already paid for that lesson once — `templates/CODEOWNERS` previously shipped
real owner handles, silently gating every PR in the adopting repo on someone who was not
watching (CHANGELOG, Fixed).

The template is therefore an **opt-in** piece: created only when a repo actually links to
ClickUp, per the blueprint's own rule that an unused scaffold is worse than none. Adding
it is consumer-visible → CHANGELOG entry + `just sync-plugin`.

### 2. The link is a pointer, never a naming scheme

`work/` keeps ADR-0006 numbering unchanged: `NNNN-slug`, repo-local, never reused. ClickUp
identity lives in the item's front-matter. Folders are **not** renamed to carry task IDs —
the mapping is not 1:1 and must not be forced to be:

- one task → one work item (the common case)
- one task with N subtasks → N work items sharing a parent pointer, **or** one item
  covering all N — chosen at pull time
- work item with no ClickUp task (internal refactor) — normal
- ClickUp task with no work item (a design review, a public post) — normal

The pointer is optional in **both** directions. That optionality is what makes the sync
partial rather than a mirror.

### 3. Front-matter schema

Carried in the item's first file (`proposal.md` or `spec.md`). The governing rule:

> **Front-matter is a timestamped snapshot, not a mirror.** Carry only what changes agent
> behaviour or is needed to write back; link the rest. Never prefer it to a live read when
> making a decision — `Synced:` is what makes staleness visible.

```markdown
- Status: In review
- Synced: 2026-08-11 — pushed: Agent Working

- ClickUp: 86abc123 — https://app.clickup.com/t/86abc123
- ClickUp-status: Agent Working
- ClickUp-path: Neil In Progress / Build / Action Items
- ClickUp-parent: 86aparent — "Auth rewrite" (pulled as subtask 2 of 5)
- ClickUp-blocked-by: 86dep001 — "Vendor API credentials" — not pulled, status: To Do
- ClickUp-blocks: 86dep002 → work/0009-session-store/
- ClickUp-related: 86lnk003 — "Public launch note" — not pulled
```

Required: `ClickUp`, `ClickUp-status`, `Synced`. The rest appear only when ClickUp has a
value — absent fields are omitted, never written empty.

**Deliberately excluded: `due`, `priority`, `tags`, assignee, description.** They change
nothing about how an agent works the item, they go stale silently, and they are one
`myclickup task <id>` away. That is the actionable/decorative cut.

Field notes:

- **All of this is readable.** `myclickup task <id> --json` emits the raw ClickUp task
  object, so `parent`, `dependencies`, `linked_tasks`, `custom_fields` are all available —
  the human formatter shows a subset, `--json` does not.
- **`ClickUp-path` needs the cache.** `GET /task/{id}` returns `space` as an ID only; the
  `Space / Folder / List` path is resolved from cached `hierarchy.json`. This is the same
  mechanism that makes `--list "Team/Build/Action Items"` work.
- **`blocked-by` / `blocks` come from `dependencies`**, split by its `type` field;
  `related` comes from `linked_tasks`.

#### What makes the graph actionable rather than decorative

Three rules, all of them behaviour-changing:

1. **Every relation carries a title or a local path — never a bare ID.** A pulled relation
   resolves to `→ work/NNNN-slug/`; an unpulled one carries its ClickUp title *and* its
   last-seen status. A bare ID is unreasonable-about-able, which is the definition of
   decorative.
2. **Blockers gate the work.** Before starting, the agent checks `ClickUp-blocked-by`. If
   any blocker is not `done`/`closed`, it **stops and reports** rather than proceeding —
   the same `status_type` rule, applied to dependencies. This is the single rule that
   turns the graph into something with teeth.
3. **Blocked status is re-read live, never trusted from front-matter.** The snapshot says
   what was true at `Synced:`; a gate decision costs one `myclickup task <id>` call. This
   is the general "snapshot, not mirror" rule at the one point where being wrong is
   expensive.

`ClickUp-blocks` is informational in the other direction: on completion, `/clickup-report`
names the now-unblocked tasks so they can be queued.

Reverse link: the ClickUp task description, or one pinned comment, carries repo name +
`work/NNNN-slug/`. For a `--subtasks` fan-out the **parent** gets *one* comment listing
the created slugs — never one comment per child. The cognitive-load rule applies to the
sync itself.

### 4. Status vocabulary — the agent-in-hand state

A distinct status is needed for *the agent has this in hand*, which is not the same as a
human being mid-task. Two statuses are added to the existing standard set:

| # | Status | `status_type` | Meaning |
|---|---|---|---|
| 1 | `To Do` | `open` | Not started. *(existing)* |
| 2 | **`Ready for Agent`** | `custom` | Scoped and queued for an agent. **The bucket** (§6). |
| 3 | **`Agent Working`** | `custom` | Pulled into a work item; agent has it in hand. |
| 4 | `In Progress` | `custom` | A **human** is actively on it. *(existing)* |
| 5 | `In Review` | `custom` | Awaiting human review / PR. *(existing)* |
| 6 | `Complete` | `closed` | Done. *(existing)* |

**`Agent Working` is the chosen name.** Legible at a glance, matches the vocabulary GitHub
shipped, and unambiguous about *running* versus *queued* — which `With Agent` (the runner
up, a nicer handoff idiom) is not.

**No `Needs Input` status is required**, because `In Progress` already is one. In a
human-only board `In Progress` is the sole active state, which is why every published
agent-kanban writeup has to invent an escalation column — a bounced item has nowhere to
go. Here the two active states are already distinct: `Agent Working → In Progress` *is*
the escalation, and it reads as a forward move on the board. That is why the agent states
are ordered before `In Progress` rather than after it.

Board order is cosmetic; the transitions are the contract:

```
To Do ──► Ready for Agent ──► Agent Working ──► In Review ──► Complete
   │              ▲                  │              ▲
   └──────────────┴──► In Progress ◄─┘ (agent blocked: needs a human decision)
```

**Completion rule is unchanged:** judge by `status_type` (`done`/`closed`), never by name.
ClickUp requires exactly one `open` status (first) and one `closed` (last); everything
between is `custom`. So both new statuses are `custom` — created as `done` they would
silently read as finished.

#### 4.1 Recording the mapping per repo — yes, worth it

Status *names* vary per Space; that variance is the whole reason the `status_type` rule
exists. A skill that hard-codes `"Agent Working"` breaks the first time a Space spells it
differently. So `.myclickup.toml` carries a **semantic-role → status-name** map, not a
list of statuses — the `[statuses]` table in §1.1.

- **A list would be a duplicate that goes stale.** A *mapping* is the thing skills need
  and ClickUp does not provide: which of this Space's statuses plays which role.
- **It is forward-compatible today.** `config.py:_read_pins` loads the TOML and reads only
  the keys it knows; unknown tables are ignored. Its one guard rejects *top-level* keys
  containing `token`/`key`, which `[statuses]` does not trip.
- **Caveat:** `[statuses]` is an unclaimed namespace in another tool's config file. If
  `myclickup` later defines it differently, this collides. Worth proposing upstream so the
  table is reserved rather than squatted.
- Repos with no ClickUp link simply omit the file — the pointer is optional in both
  directions (§2).

### 5. Field ownership — where conflicts get resolved

Partial manual sync has no merge problem *provided* ownership is fixed per field:

- **ClickUp owns:** existence, title, priority, due date, parent/child, assignee, tags.
- **`work/` owns:** the plan, the notes, the decision trail.
- **Status is the only shared field.** `work/` *proposes* a transition; ClickUp is
  authoritative once written.
- **Re-hydration never clobbers.** A second pull appends, or reports a diff. It must never
  overwrite `notes.md`.
- **Human-triggered, never continuous** (for now — see §6).

### 6. The bucket, and the automation direction

**The bucket is a status, not a List.** Three candidates were considered:

- **Status `Ready for Agent`** — travels with the task, works across every list, is a
  native ClickUp automation *trigger*, and leaves the task in its project context.
  **Chosen.**
- **Tag `agent`** — cross-list and `myclickup tag/untag` supports it, but it is a weaker
  automation trigger. Keep as a secondary *capability* marker (e.g. `agent-safe`).
- **A dedicated List (`Agent Queue`)** — **rejected as primary.** Moving a task out of its
  home list destroys "how it connects to the bigger picture", which is the whole reason
  ClickUp is in this design. A saved **view** filtered on status gives the same board
  without moving anything.

So: *the status is the queue, a view is the board, the list stays where your mental model
puts it.*

**Side track — ClickUp as a driver for scheduled work. Decided in shape, NOT implemented.**

The mechanism is **polling on a schedule**, not webhooks: ClickUp's `Call webhook`
automation action needs an inbound endpoint, and the sandbox has no route for one. Polling
needs nothing new. Claude Code already has the scheduling primitives (`/schedule` cloud
routines, `/loop`, cron), so **none are set up now** — no cron entry, no routine, no empty
skill file. Dead scaffolding is worse than none.

What ships now is only what a future poller would read unchanged:

- **`[statuses].agent_ready`** (§4.1) — the poller's query target. Needed by
  `/clickup-pull` anyway, so it is not speculative.
- **`[work_sync].wip_limit`** in `.myclickup.toml` — a cap on concurrently `Agent Working`
  items. Honoured by the human-invoked skills as a warning from day one; becomes a hard
  stop when polling arrives. A queue drained unattended without a cap turns
  `Ready for Agent` into a dumping ground.
- **A stated poll contract**, so the loop is a wiring job later, not a redesign:
  `myclickup tasks --list <queue> --json` → filter `status.status == agent_ready` →
  oldest first, up to `wip_limit` → `/clickup-pull` each → set `Agent Working`.

Two blockers to resolve before that loop can run unattended, recorded now so they are not
discovered later:

- **Writes prompt for permission every time, by design.** An unattended routine cannot set
  `Agent Working` without an explicit permission-policy decision. That is a deliberate
  choice to make, not a bug to route around.
- **Nothing closes the loop on failure.** A crashed session leaves a task in
  `Agent Working` forever (Open question 3).

Revisit once §1–§5 have real use.

### 7. Mechanics

Two human-invoked skills:

- **`/clickup-pull <task-id|url> [--subtasks]`** — creates `work/NNNN-slug/` with hydrated
  front-matter and a `## From ClickUp` section quoting the description verbatim.
  `--subtasks` fans out to N items sharing `ClickUp-parent`.
- **`/clickup-report <work-item>`** — `--dry-run` first, always, then the status update
  and/or comment. Bounded to: status change, hurdle comment, significant-change comment.

`--dry-run` matters more than usual here: the permission prompt shows argv, not what it
resolves to, and the output lands in a surface a human reads visually.

**Human prerequisite:** the statuses in §4 must be created in the ClickUp Space by hand.
Custom statuses are per-Space (with per-List overrides), `myclickup` has no
status-definition command, and ClickUp requires a status to exist in the task's home
location before anything can set it.

### 8. Blueprint changes

- Replace `reference/agentic_native_repo_scaffold.md:77` — the "skip `work/` entirely"
  sentence — with the two-projections model.
- Add a row to the provenance table: *"Where does this sit in the plan / who else cares?"*
  → external tracker, linked from the work item's front-matter.
- `templates/.gitignore` gains `.cache/`. **Done**, with a CHANGELOG entry under the
  unreleased `0.1.0` (no version bump — nothing has shipped that version yet, so there is
  no consumer to signal).
- **New `templates/.myclickup.toml`** — generic, `workspace_id` empty (§1.2), with the
  `[work_sync]` and `[statuses]` tables present and commented as the shape to fill in.
- The blueprint gains an **opt-in — external tracker** bullet alongside the existing
  opt-in tiers, so a repo with no ClickUp link never grows the file.
- `/myconv:apply-conventions` treats filling in `workspace_id` and `scope` as a **human
  step**, in the same class as replacing `{{PROJECT_NAME}}` — never guessed.
- Remaining blueprint edits are consumer-visible → CHANGELOG entry, `just sync-plugin`,
  `just validate` when they land.

### 9. Is this implementable from here?

Yes, in three layers, and only one thing is genuinely blocked.

**Layer 1 — done.** `.cache/` ignored in both gitignores; CHANGELOG entry recorded.

**Layer 2 — blocked on one answer, and only for *this repo's* copy.** This repo's
`.myclickup.toml` needs a real workspace ID plus the `scope` this repo works within. The
token sees four workspaces and currently resolves to the wrong one. Everything downstream
reads this file, so nothing can be verified end-to-end until it exists. *(One decision,
then unblocked.)*

The **template** copy is not blocked by this at all — it ships empty by design (§1.2), so
it can be written before the workspace question is answered.

**Layer 3 — implementable once Layer 2 lands**, in this order:

1. Human creates `Ready for Agent` and `Agent Working` in the chosen Space (UI step; no
   CLI can do it) and adds the `[statuses]` map to `.myclickup.toml`.
2. ADR-0008 records the two-projections model and the field-ownership split — this is
   direction-setting, and AGENTS.md requires the ADR before the change.
3. `/clickup-pull` — pure read plus local file writes. Runs unprompted; no ClickUp write
   surface at all. **Testable immediately after step 1.**
4. `/clickup-report` — the only piece touching ClickUp. `--dry-run` first by construction,
   so it is reviewable before anything lands in a human-facing surface.
5. Blueprint + template edits, then `just sync-plugin` / `just validate`.

**Nothing here needs new tooling.** Every read the design depends on is an existing
`myclickup` read command, and every write is one of `update --status` / `comment` — which
is the whole of the tool's write vocabulary. The one capability gap is status *creation*,
and that is a one-off human UI step, not a recurring dependency.

**Honest limits.** The design is unproven past ~1 item; the not-1:1 mapping cases and the
subtask fan-out are reasoned, not observed. Statuses are cheap to rename later; the
front-matter schema is the part that would be expensive to change after a dozen items
carry it, so it is deliberately minimal.

## Open questions

1. **Beads.** `ADOPTION.md` §3 retires plan files into `bd` while ADR-0006 makes `work/`
   the single in-flight pipeline — an unresolved tension this proposal sits on top of.
   **Deliberately deferred**: beads is not initialised here (`cv` reserved, never run) and
   adoption probability is currently low. Prove the ClickUp ↔ code connection first, then
   reassess. The risk accepted: if beads later lands as the execution ledger, the pointer
   chain becomes ClickUp → bd → `work/` and this convention needs revision. Building both
   bridges now would be the more expensive mistake.
2. **Which workspace, and which Space is the driver?** *(The one blocking question.)* The
   token sees four workspaces and defaults to the wrong one; `Ready for Agent` has to
   exist somewhere concrete, and `.myclickup.toml` has to name it.
3. **Does `Agent Working` need a heartbeat?** A card stuck in it for days is
   indistinguishable from a crashed session — and this gets worse, not better, once
   polling drains the queue unattended. A `Synced:` age check in `/wrap-up` may be enough;
   a stale-detector is the heavier option. Linear ships a `stale` session state for
   exactly this.
4. **Should `/clickup-pull` create the work item's number, or reserve it?** Two concurrent
   pulls could race on `NNNN`.

## Alternatives

- **Full bidirectional mirroring of body content.** Rejected — destroys ClickUp's
  glanceability, and every published account of tracker↔agent integration names
  source-of-truth ambiguity and stale context as *the* failure mode.
- **Tracker-only (drop `work/` when ClickUp is in use)** — the current blueprint line.
  Rejected: it leaves the agent's reference bundle homeless, and ClickUp is a poor place
  to read a plan.
- **`work/`-only (ignore ClickUp).** Rejected — loses ordering, the bigger picture,
  non-code items, and the shareable human view.
- **Folder names carrying the task ID** (`work/CU-86abc123-slug/`). Rejected — breaks
  ADR-0006's numbering invariant, and cannot express the not-1:1 cases.
- **A dedicated `Agent Queue` List as the bucket.** Rejected — see §6.
- **A gitignored `.clickup/` sync store.** Rejected — that is `.cache/myclickup/`, which
  already exists and is already specified (myclickup ADR-0004).

## Prior art

- **GitHub agent sessions** (GA, Mar 2026) — assigning an issue to a coding agent surfaces
  a live session state on the issue (*queued / working / waiting for review / completed*)
  with a link to logs. Work in the repo and PR; issue carries status and a pointer.
- **Linear `AgentSession`** — six user-visible states: `pending`, `active`, `error`,
  `awaitingInput`, `complete`, `stale`, plus a structured plan whose steps are
  `pending | inProgress | completed | canceled`. Linear's coding sessions draw on
  *repository* guidance files alongside issue context — tracker holds intent, repo holds
  the how.
- **GitHub Agentic Workflows** — names the bounded write surface outright:
  `safe-outputs: [add-comment]` on a status-change trigger. The agent structurally cannot
  do more than comment on the tracking issue.
- **Iterative-kanban writeups** — add agent-specific columns (`Ready for Agent`,
  `Agent Processing`, `Agent Revising`), an explicit human-review state, and an escalation
  column; they flag WIP limits on the agent-ready column as necessary.
- **agent-kanban** (`saltbo/agent-kanban`) — task lifecycle `Todo → In Progress → In
  Review → Done` driven by verbs `claim / review / complete / reject / release`, which is
  close to `myclickup`'s own `claim` + `update --status` surface.
- **Beads** — `issues.jsonl` is explicitly "an export/interchange file, NOT the source of
  truth". Same discipline: project a slice, never mirror.
- **Spec-driven development** — spec versioned in-repo; IBM's writeup lists *"using
  external systems (issue trackers) as the source of truth to introduce intentional
  separation"* as a recognised hybrid.
