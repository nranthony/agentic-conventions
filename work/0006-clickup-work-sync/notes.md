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
