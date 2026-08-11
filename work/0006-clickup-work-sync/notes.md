# Notes — where this actually stands

**Not archived on purpose.** The proposal is Accepted and its rationale is distilled into
ADR-0008, but the item is still in flight: nothing has been verified against a live
ClickUp workspace. Archiving now would file an unproven design as settled history.

## Done (2026-08-11, uncommitted)

- **ADR-0008** — the decision: two projections of one item, asymmetric partial sync,
  field ownership, status set, queue-is-a-status, config layout.
- **`.gitignore` + `templates/.gitignore`** — `.cache/` ignored. Was a live hazard: any
  myclickup read that misses the cache writes it, and cached space/list names may carry
  customer identifiers.
- **`.myclickup.toml`** (this repo) and **`templates/.myclickup.toml`** — both with
  `workspace_id` deliberately empty, `[work_sync]` scope/queue/wip_limit and `[statuses]`
  role→name map scaffolded.
- **`/clickup-pull` + `/clickup-report`** — live in `.claude/skills/`, mirrored into
  `templates/.claude/skills/` and `plugins/myconv/skills/`, with the justfile's
  `sync-plugin` / `check-plugin-sync` / `check-skill-mirrors` targets extended.
- **Blueprint** — the "skip `work/` entirely" line replaced with an opt-in external-tracker
  section; provenance-table row; `.myclickup.toml` in the layout.
- **`work/README.md`, `AGENTS.md`, `CHANGELOG.md`** updated. All `just` gates pass.

## Blocked on a human

1. ~~Create the agentic-work workspace.~~ **Done** — "The Vault" (`90141509251`), pinned
   2026-08-11. `whoami` resolves it cleanly with no fallback warning.
2. ~~Fill `workspace_id` and `[work_sync].scope`.~~ **Done** — scope is `[]` (the whole
   workspace) since The Vault is dedicated to agentic tooling.
3. **Add two statuses to the Space**, giving:
   `To Do → Ready for Agent → Agent Working → In Progress → In Review → Complete`.
   Both new ones must be `custom` type — created as `done` they would silently read as
   finished. **Still outstanding**: no CLI can define statuses, and `myclickup spaces`
   normalises its payload to id+name so the current status set isn't even readable from
   here. ClickUp UI step.
4. **Name the Space and List.** Both are still on ClickUp's defaults ("Space"
   `90147033108` / "List" `901419010749`), so `[work_sync].queue` is left unset — a path
   pinned to a default name breaks silently on rename.

## First live pull — 2026-08-11, task `86bbc7we3`

Ran `/clickup-pull 86bbc7we3` against The Vault → `Codebase / Agentic Conventions`.
Preflight, fetch, path resolution and item creation all worked; the pull is read-only and
touched nothing on the board. Produced `work/0007-testing/` (a test fixture — delete once
these findings are absorbed). Three things surfaced:

1. **Defect — status names come back lower-cased.** The API returns
   `status.status == "ready for agent"` however it is typed in the UI, so an exact match
   against `[statuses] agent_ready = "Ready for Agent"` finds nothing. Would have broken
   the `agent_working` count and, later, the whole poller filter. Fixed: both skills and
   the pins file now say match case-insensitively, send the mapped spelling on writes.
2. **Design confirmed, for a second reason.** `GET /task/{id}` returns `space` as a bare
   `{id}` (as expected) *and* a `folder` of `{"name": "hidden", "hidden": true}` for a list
   sitting directly under a Space. Reading that field verbatim would have written
   `Codebase / hidden / Agentic Conventions`. Resolving from cached `hierarchy.json`
   avoids both problems; the skill now states why so nobody "simplifies" it back.
3. **Gap — slug derivation.** Title `0006 - testing` yielded `work/0007-testing/`: the
   leading reference collides confusingly with local numbering, and what remains does not
   identify the item. Skill now says strip the leading reference and propose a better slug
   rather than creating a thin one silently.

Also set `[work_sync].queue = "Codebase/Agentic Conventions"` now that the Space and List
have real names.

## Second live pull — 2026-08-11, subtask fan-out + blocker

Fixture: `86bbc89p1` "Continue Clickup Sync testing" `[ready for agent]` with two children
(`86bbc89xm`, `86bbc89yp`), and `86bbc8ahm` `[in reveiw]` blocking the second child.
Pulled to `work/0008-testing-task-1/` and `work/0009-testing-task-2/`. Two more defects,
both found *before* writing the items:

4. **Defect — subtasks are not discoverable from the parent.** `GET /task/{id}` has no
   `subtasks` array; the only `subtasks` string in the payload is inside
   `sharing.public_fields`. The skill's `--subtasks` instruction ("fetch the parent, then
   each child") had no mechanism behind it. Children are visible only from *their* side
   via `parent`, so the route is `myclickup tasks --list <path> --all --json` filtered on
   `parent == <id>`. Fixed in the skill.
5. **Defect — dependency direction is not `type`.** One edge is stored as
   `{"task_id": A, "depends_on": B, "type": 1}` and appears **identically on both A and
   B** — `type` was `1` on both sides of the same edge. The skill said to split
   `blocked-by` / `blocks` "by its `type` field", which would have inverted half of all
   relations. Direction comes from comparing `task_id` / `depends_on` against the task you
   fetched. Fixed.

Also observed: **relations sit on the children, not the parent.** `86bbc89p1` reports
`dependencies: []` while its second child is genuinely blocked — so a fan-out must read
each child's own payload, not infer from the parent. Noted in the skill.

**The blocker gate fired correctly.** `86bbc8ahm` is `status_type: custom` (not
`done`/`closed`), so `work/0009` is marked BLOCKED and carries the named blocker plus its
last-seen status rather than a bare ID.

**Still unexercised:** `linked_tasks` / `ClickUp-related` (no fixture has one), re-pull
diffing, and every write path — `/clickup-report` cannot run until the two agent statuses
exist in the Space.

## Unverified until a real task exists

Everything below is reasoned from the ClickUp API shape and the myclickup source, never
observed:

- front-matter hydration end to end
- `ClickUp-path` resolution from cached `hierarchy.json` (the API returns `space` as a
  bare ID)
- the `dependencies` split into `blocked-by` / `blocks` by its `type` field
- the `--subtasks` fan-out
- whether `[statuses]` and `[work_sync]` really survive `myclickup`'s config loader in
  practice (verified by reading `config.py`, not by running it)

**First live pull is the acceptance test.** Statuses are cheap to rename afterwards; the
front-matter schema is the expensive part to change once a dozen items carry it, which is
why it shipped minimal.

## Deliberately deferred

- **Scheduled polling.** Shape agreed (poll, never webhook — the sandbox has no inbound
  route), nothing implemented. Two open blockers: myclickup writes prompt for permission
  every time by design, so an unattended routine cannot set status without a policy
  decision; and nothing closes the loop when a session crashes mid-item.
- **Beads.** `conventions/beads/ADOPTION.md` §3 retires plan files into `bd` while ADR-0006
  makes `work/` the single in-flight pipeline — a pre-existing tension this sits on top of.
  Not reconciled; if beads later lands the chain becomes ClickUp → bd → `work/` and
  ADR-0008 needs superseding.
## Resolved after the wrap-up

- **`apply-conventions` and the ClickUp skills.** Settled: it does **not** place them in a
  repo with no tracker link, and it now asks for the workspace ID and scope up front
  rather than leaving a half-configured pins file behind. Unlinked, the skills would be
  the dead instructions that skill's own guardrail forbids. (`a27d9d3`)
- **"Tracker link" is defined** in the blueprint's external-tracker bullet — a property of
  the repo, one test, three states. (`3e0e661`)
