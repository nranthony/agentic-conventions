---
name: clickup-report
description: Report a work/ item's progress back to its linked ClickUp task — a status transition and/or a short comment on a hurdle or change of direction. Dry-run first, always. Use when starting, blocking on, or finishing tracked work. Requires a repo-root .myclickup.toml with a pinned workspace; stops immediately without one.
argument-hint: <work item path> [status | "comment text"]
---

# Report a work item back to ClickUp

Report on: $ARGUMENTS

**This is the only skill that writes to ClickUp.** Its whole surface is a status change
and a comment.

The convention behind this is recorded as **ADR-0008** in the conventions repo
(`docs/adr/0008-clickup-work-sync.md`). Deliberately not a link: this file ships inside a
plugin, and a relative path out of the payload resolves nowhere.

## What may cross, and what may not

May cross:

- a **status transition** — `Ready for Agent` → `Agent Working` → `In Review` / `Complete`,
  or `Agent Working` → `In Progress` when handing back to a human
- a **short comment** on a hurdle, a blocker hit, or a significant change of direction

**Must not cross:** plan or notes content, spec text, diffs, file paths, ADR bodies,
command output, or anything longer than a few sentences. A tracker's value is being
low-cognitive-load; pasting markdown into it destroys the one thing it is better at than
the repo. If the detail matters, it belongs in the work item — link the item, don't quote
it.

## Preflight — stop, don't improvise

1. **`myclickup` on PATH?** If not, stop with: *"myclickup isn't installed here — it's
   baked into the sandbox image, so this is a human step."* Never attempt to install it
   (denied), and never fall back to raw HTTP against the ClickUp API.
2. **`.myclickup.toml` present, `workspace_id` non-empty?** If not, stop — same rule as
   `/clickup-pull`. Never guess an ID.
3. Resolve the target status through `[statuses]`, never by hard-coded name. **Compare
   case-insensitively** — ClickUp returns status names lower-cased (`"ready for agent"`)
   whatever the UI shows, so an exact match against `"Ready for Agent"` finds nothing.
   Send the `[statuses]` spelling on writes; read back case-insensitively.
4. Read the item's `ClickUp:` front-matter. No pointer means nothing to report — say so
   rather than guessing which task was meant.
5. **Re-read the task live** (`myclickup task <id> --json`) before deciding anything. The
   front-matter is a snapshot; a human may have moved the task since.

## Dry-run first — always

    myclickup --dry-run update <id> --status "<resolved name>"
    myclickup --dry-run comment <id> <text>

`--dry-run` goes **before** the subcommand; `--json` / `--account` / `--live` go after it.
Show the resolved request, then run the same command without `--dry-run` and answer the
permission prompt. This matters more here than usual: the prompt shows argv, not what it
resolves to, and the output lands in a surface a human reads visually.

## On completion

Before reporting `Complete`:

- confirm the work item's own exit rule is satisfied — anything durable distilled into an
  ADR or `docs/`, then archived
- check `ClickUp-blocks:` and **name the now-unblocked tasks** in your summary to the
  human, so they can be queued. Do not silently re-status them.

## After writing

Update the item's front-matter: `ClickUp-status` to the new value and
`Synced: <date> — pushed: <status>`. The push is not done until the local record says so.

## Never

- Batch a comment per subtask. A fan-out reports **once, on the parent**, listing the
  created item slugs.
- Move a task between Lists. The queue is a status; tasks stay where the human's mental
  model put them.
- Attempt to create a status. Custom statuses are per-Space and defined in the ClickUp UI
  by a human; `myclickup` has no command for it, and ClickUp rejects a status that does
  not exist in the task's home location.
- Delete anything. There is no delete command; `untag` removes a tag and nothing more.
