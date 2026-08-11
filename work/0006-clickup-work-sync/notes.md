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

1. **Create the agentic-work ClickUp workspace.** Deliberately deferred — no suitable
   workspace exists yet, which is why the pin is empty rather than pointed at one of the
   four the token already sees.
2. **Add two statuses to the chosen Space**, giving:
   `To Do → Ready for Agent → Agent Working → In Progress → In Review → Complete`.
   Both new ones must be `custom` type — created as `done` they would silently read as
   finished. No CLI can define statuses; this is a ClickUp UI step.
3. **Fill `workspace_id` and `[work_sync].scope`** in `.myclickup.toml`.

## Unverified until step 3 lands

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
- **Whether `apply-conventions` should place the ClickUp skills into repos with no tracker
  link.** They are inert there (description names the requirement, preflight stops), but
  the placement judgment is currently unstated.
