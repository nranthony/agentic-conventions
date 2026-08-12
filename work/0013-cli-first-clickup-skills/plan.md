# Plan: CLI-first rewrite of the two ClickUp skills

- Status: Draft
- Author: agent (Fable 5) + nanthony
- Reference: held as WP8.1 of `work/0011-skill-audit-fixes/` ("CLI-first boundary —
  decided: hold"); released and decided 2026-08-12
- Synced: not tracked in ClickUp

Pre-decided work, so this opens straight as a plan (per `work/README.md`).

## Problem

Both ClickUp skills were written against `myclickup` 0.2.0 and hand-encode mechanisms the
CLI did not then have: subtask discovery via a whole-list scan filtered on `parent`, the
dependency-direction split done by comparing `task_id`/`depends_on` against the task you
fetched, and a hidden-folder workaround that resolves `ClickUp-path` out of the cached
`hierarchy.json` because the raw payload says `folder: {"name": "hidden"}`.

`myclickup` 0.3.0 is now the in-container CLI and closes every one of those gaps natively.
Verified 2026-08-12 against the installed 0.3.0:

- `subtasks <id>` is a command. `task <id> --subtasks` also inlines them.
- `task <id> --json` emits derived **`blocked_by`** and `blocks` arrays alongside the raw
  `dependencies` — direction already resolved for the task you asked about.
- `task <id> --json` emits a derived **`path`** (`"Codebase/Agentic Conventions"`) that
  omits the implicit hidden folder, even though the raw `folder.name` in the same payload
  still reads `"hidden"`.
- `set-status <id> "<name>"` writes the status field and nothing else, validating the name
  against the list's statuses before sending.
- `statuses --list <path|id>` lists what a list actually defines, with each status's `type`.
- `--live` / `--cached` are explicit flags on every read; `--dry-run` is accepted at the
  root **and** on each writing subcommand.

Carrying the workarounds now costs twice: they are longer than the CLI call that replaces
them, and they teach a shape of the payload that is no longer the shortest true path.

## Decided scope

Mechanism moves to the CLI; policy stays in the skill. Both skills get shorter.

1. **`clickup-pull`** — subtask discovery becomes `subtasks <id> --json --live` (policy
   kept: one item per child, ask beyond a handful, read each child's own payload because
   relations sit on children). The direction-derivation block is replaced by "use
   `blocked_by` / `blocks`". The `hierarchy.json` path workaround is replaced by "use the
   payload's derived `path`". Status discussion points at `statuses`.
2. **`clickup-report`** — the transition writes via `set-status <id> "<resolved name>"`
   instead of `update --status`; flag-ordering prose restated to what 0.3.0 actually
   accepts; the live re-read and the blocker gate name `--live` and the derived
   `blocked_by` explicitly. Preserved verbatim in behaviour: `disable-model-invocation`,
   dry-run-first, the what-may-cross policy, the completion checks, the never list.
3. **Both** gain a version-floor preflight step: `myclickup --version` must be ≥ 0.3.0.
   This replaces nothing — it is insurance against image/skill skew, since a 0.2.x CLI has
   no `subtasks` and no `set-status` and its `task` output lacks the derived fields.
4. **Supporting**: `templates/.myclickup.toml`'s "verified against 0.2.0" claims move to
   0.3.0; plugin version 0.2.0 → 0.3.0 in both manifests with a CHANGELOG entry; a line
   appended to `work/0011-skill-audit-fixes/notes.md` recording that WP8.1 executed here.
5. **Unplanned correction, found while re-verifying those claims.** The 0.2.0 three-state
   pin table is no longer true. Under 0.3.0, an empty `workspace_id` no longer fails with
   `HTTP 400` — it falls back to the token's first workspace with a warning, exactly like
   an absent key (verified with throwaway config files against the live API, read-only).
   That inverts the old "empty is the loudest of the three" reasoning slightly and, more
   importantly, makes `clickup-pull`'s preflight claim ("every workspace-scoped call would
   fail") false in a dangerous direction: an unpinned repo now reads a real board that is
   merely the wrong one. Corrected in both `.myclickup.toml` files and the pull preflight.
   The conclusion is unchanged — ship it empty, never guess an ID.

`docs/adr/0008-clickup-work-sync.md` is deliberately **not** edited for point 5: its
erratum is a dated observation against 0.2.0 and the ADR log is append-only. If the pin
semantics ever need restating as a decision rather than as operational wording, that is a
new ADR, not a rewrite of this one.

Out of scope: `docs/adr/0008-clickup-work-sync.md` and `work/README.md`. The policy this
rewrite implements is unchanged — only the mechanism moves. ADR-0008's erratum stays as
written; it is a dated observation against 0.2.0 and the ADR log is append-only.

## Completion note

Landed 2026-08-12 in commit `<hash>`.

| Skill | Before | After |
|---|---|---|
| `clickup-pull` | 139 | 136 |
| `clickup-report` | 101 | 110 |

**Only one of the two shrank, and that is the honest result, not a failure of the edit.**
Nearly all the 0.2.0-era workaround prose lived in `clickup-pull`: the "parent payload does
not list its children" block with its `sync` + `tasks --list` scan, the
`task_id`/`depends_on` direction table, and the `hierarchy.json` / `folder: "hidden"`
explanation — perhaps 30 lines of mechanism, replaced by `subtasks`, two array names and one
field name. Against that it *gained* the version-floor step, the `statuses` pointer and the
corrected empty-pin wording, netting -3. `clickup-report` had almost no workaround to shed —
its rewrite is a retarget (`update --status` → `set-status`) plus the same three additions —
so it grew by 9. Counted in what a reader has to hold, both are lighter: the removed lines
were payload-shape explanation, the added ones are commands and preconditions.

Two facts were verified against the installed 0.3.0 rather than assumed, since both could
have gone the other way: direction **is** derived (`blocked_by`/`blocks` on the task
payload), and path **is** derived (hidden folder omitted). One nuance survives into the
skill: children returned by `subtasks --json` are list-view summaries whose `blocked_by`,
`blocks` and `path` are `null`, so the "read each child's own payload" policy is now
load-bearing for a mechanical reason, not only a policy one.

Archive this item once the plugin's 0.3.0 entry ships; nothing durable is left in it that
the CHANGELOG and the skills themselves do not already carry.
