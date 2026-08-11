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
5. `myclickup status` — if the cache is stale or absent, `myclickup sync` first.
6. If `[work_sync].wip_limit` is set, count existing items whose `ClickUp-status` matches
   the `agent_working` name. At or over the limit, **warn and ask** before adding another.

## Pull

    myclickup task <id> --json

That emits the raw ClickUp object — `parent`, `dependencies`, `linked_tasks` and
`custom_fields` are all present, not just the fields the human formatter prints.

With `--subtasks`: fetch the parent, then each child, and create **one item per child**,
each carrying `ClickUp-parent`. Ask first if there are more than a handful — a fan-out of
twenty items is rarely what was wanted.

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

- **`ClickUp-path` comes from the cache.** `GET /task/{id}` returns `space` as a bare ID;
  resolve the `Space / Folder / List` path from cached `hierarchy.json`.
- **`blocked-by` / `blocks` come from `dependencies`**, split by its `type` field;
  `related` comes from `linked_tasks`.
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
