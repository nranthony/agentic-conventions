---
name: clickup-pull
description: Pull a ClickUp task (or its subtasks) into a work/NNNN-slug/ item, hydrating front-matter with identity, path and the dependency graph. Read-only against ClickUp — creates local files only. Use when activating a tracked task for agent work. Requires a repo-root .myclickup.toml with a pinned workspace; stops immediately without one.
argument-hint: <task-id or ClickUp URL> [--subtasks]
---

# Pull a ClickUp task into work/

Activate: $ARGUMENTS

**This skill never writes to ClickUp.** Every command it runs is a read. Setting the
task's status to `Agent Working` is `/clickup-report`'s job, so a pull can be reviewed
before anything becomes visible on the board.

The convention behind this — a tracker and `work/` are two projections of one item, synced
partially and asymmetrically — is recorded as **ADR-0008** in the conventions repo
(`docs/adr/0008-clickup-work-sync.md`). Deliberately not a link: this file ships inside a
plugin, and a relative path out of the payload resolves nowhere.

## Preflight — stop, don't improvise

1. **`myclickup` on PATH?** If not, stop with: *"myclickup isn't installed here — it's
   baked into the sandbox image, so this is a human step."* Never attempt to install it
   (denied), and never fall back to raw HTTP against the ClickUp API.
2. **`.myclickup.toml` at the repo root?** If absent, this repo has no tracker link. Say
   so and stop — do not create one uninvited; it is an opt-in piece.
3. **`workspace_id` non-empty?** If empty, stop — the repo is declared-but-not-pinned, and
   every workspace-scoped call would fail with `HTTP 400: Invalid workspace id`. **Do not
   guess an ID**: an absent key falls back to the token's first workspace with a warning,
   and a wrong one resolves silently against another workspace's board. Only a correct pin
   is safe, so ask for it.
4. Read `[statuses]` from that file. **Never hard-code a status name** — names vary per
   Space, which is the same reason completion is judged by `status_type`.
   **Compare case-insensitively.** ClickUp returns status names lower-cased
   (`"ready for agent"`) regardless of how they were typed in the UI, so an exact match
   against a `[statuses]` value like `"Ready for Agent"` silently finds nothing.
5. `myclickup status` — if the cache is stale or absent, `myclickup sync` first.
6. If `[work_sync].wip_limit` is set, count existing items whose `ClickUp-status` matches
   the `agent_working` name. At or over the limit, **warn and ask** before adding another.

## Pull

    myclickup task <id> --json

That emits the raw ClickUp object — `parent`, `dependencies`, `linked_tasks` and
`custom_fields` are all present, not just the fields the human formatter prints.

With `--subtasks`: **the parent payload does not list its children.** `GET /task/{id}`
has no `subtasks` array (the only `subtasks` string in it is inside `sharing.public_fields`
— don't be fooled). Children are discoverable only from *their* side, via `parent`:

    myclickup sync
    myclickup tasks --list "<path>" --all --json   # includes subtasks

then select the entries whose `parent` equals the target ID, and create **one item per
child**, each carrying `ClickUp-parent`. Ask first if there are more than a handful — a
fan-out of twenty items is rarely what was wanted.

Note that relations often sit on the **children**, not the parent: a parent can show empty
`dependencies` while a child is genuinely blocked. Read each child's own payload.

## Create the item

`work/NNNN-slug/proposal.md`, where `NNNN` is the next free number across active **and**
archived items (numbers are never reused) and the slug is derived from the task title, not
its ID.

Front-matter — required fields first, then only those ClickUp actually has a value for.
Absent fields are **omitted, never written empty**:

```markdown
- Status: Draft
- Synced: <YYYY-MM-DD> — pulled

- ClickUp: <id> — <url>
- ClickUp-status: <status name>
- ClickUp-path: <Space / Folder / List>
- ClickUp-parent: <id> — "<title>" (pulled as subtask N of M)
- ClickUp-blocked-by: <id> — "<title>" — not pulled, status: <name>
- ClickUp-blocks: <id> → work/NNNN-slug/
- ClickUp-related: <id> — "<title>" — not pulled
```

Then a `## From ClickUp` section quoting the task description **verbatim**, and the
repo's own proposal template headings below it.

Rules that make this worth having:

- **`ClickUp-path` comes from the cache, never from the task payload.** Two reasons:
  `GET /task/{id}` returns `space` as a bare `{id}` with no name, *and* its `folder` field
  reads `{"name": "hidden", "hidden": true}` for any list that sits directly under a Space.
  Reading that field verbatim writes a path like `Codebase / hidden / Agentic Conventions`.
  Resolve from cached `hierarchy.json` instead, which omits the implicit folder entirely.
- **Slug from the task title, cleaned.** Strip any leading work-item reference the title
  carries (`"0006 - testing"` → `testing`) so the local number stays the only number in the
  path. If what remains is too thin to identify the item later, say so and propose a better
  slug rather than creating `work/0007-testing/` and moving on.
- **`blocked-by` / `blocks` come from `dependencies`, split by direction — not by `type`.**
  One edge is stored as `{"task_id": A, "depends_on": B, "type": 1, ...}` and appears
  **identically on both A and B**, so the record alone tells you nothing about which side
  you are on. `type` is the same on both sides and is not the direction. Compare against
  the task you fetched:
  - `task_id` == this task → this task is **blocked-by** `depends_on`
  - `depends_on` == this task → this task **blocks** `task_id`

  `related` comes from `linked_tasks`, which is a separate array.
- **Never write a bare ID.** Every relation carries either `→ work/NNNN-slug/` when that
  task has also been pulled, or its title plus last-seen status when it has not. A bare ID
  cannot be reasoned about, which is the definition of decorative.
- **Exclude `due`, `priority`, `tags`, assignee, description-as-metadata.** They change no
  agent behaviour and go stale silently. They are one `myclickup task <id>` away.

## Re-pulling an existing item

Never clobber. Report a diff against the current front-matter and ask before applying it.
`notes.md`, `plan.md` and `spec.md` are owned by the repo and are never touched by a pull.

## Then

Tell the human what was created and what the next step is — normally
`/clickup-report <item>` to move the task to `Agent Working`. Do not run it for them.
