# Plan: act on the plugin-skills audit (2026-08-12)

- Status: Draft
- Author: agent (Fable 5) + nanthony
- Synced: not tracked in ClickUp yet — pull/report later if wanted

## Problem and intended outcome

A full audit of the five skills shipped in the `myconv` plugin (apply-conventions,
make-plan, wrap-up, clickup-pull, clickup-report) found the copies in perfect sync and
the content largely excellent, but surfaced a set of defects: sandbox-only wording that
ships to every consumer machine, a status-mapping gap that makes one instruction
unsatisfiable, template defaults that contradict the repo's own fail-loudly doctrine,
an advertised-but-unimplemented skill argument, stale marketplace/README skill lists,
and silent blind spots in the justfile checks. This plan fixes the mechanical items and
isolates the genuinely direction-setting ones for a human decision.

Decisions already made by the owner (2026-08-12, in-session):

- The plugin must work on **sandbox and normal machines**; outside the sandbox the
  ClickUp skills should warn and ask the human to clone the `myclickup` repo and
  install the wheel — never claim installs are impossible.
- **Collaborators may consume this later** — genericise accordingly, but don't split
  the plugin yet.
- **Multi-runtime is an aspiration**: keep skill bodies plain-markdown procedure;
  don't deepen Claude-Code-only coupling where avoidable.

## How to execute this plan (read first)

- **Execution order: WP7 (the prune) runs FIRST.** It was decided 2026-08-12 via the
  deployment owner's handoff (`handoff-myconv-skill-prune.md` in this folder) and it
  changes where the canonical skill sources live. Every WP below was originally
  written against the pre-prune four-copy layout; after WP7, read any instruction to
  "edit both copies" / "keep mirrors byte-identical" as simply: edit
  `.claude/skills/<name>/SKILL.md` (the single canonical copy) and run
  `just sync-plugin`.
- **Canonical sources (post-prune)**: the four shared skills live only at
  `.claude/skills/<name>/SKILL.md`; the justfile syncs them into the plugin payload.
  `apply-conventions` is authored in place at
  `plugins/myconv/skills/apply-conventions/SKILL.md` — edit it there only.
- **Never touch `~/.claude/skills/myconv/`** (the in-container seeded copy). It is a
  derived cache at the end of a vendoring chain owned by the windows-ai-sandbox repo;
  its convergence step overwrites divergent copies on every profile `up`. Your job
  ends at the upstream commit — the human re-vendors from the sandbox side.
- **After any edit** to `reference/`, `templates/`, or the shared skills:
  `just sync-plugin && just check-plugin-sync && just check-skill-mirrors && just validate`.
- Consumer-visible changes get a `CHANGELOG.md` line. The current entry is
  `0.1.0 — unreleased`, so fold new lines into it; no version bump is owed until 0.1.0
  ships (per the changelog's own status).
- Commit locally with clear messages; never push.
- Work packages 1–6 are independent and can be run by separate agents; WP7 is the
  needs-decision list and must NOT be implemented without the owner's answer.

---

## WP1 — Make the ClickUp skills' preflight portable

**Files:** `.claude/skills/clickup-pull/SKILL.md` + `.claude/skills/clickup-report/SKILL.md`
and their `templates/.claude/skills/` mirrors (4 files, one shared wording).

The preflight step 1 currently reads: *"myclickup isn't installed here — it's baked
into the sandbox image, so this is a human step."* and *"Never attempt to install it
(denied)"*. Both claims are true only in the author's sandbox. Replace with
environment-aware wording, keeping the never-fall-back-to-raw-HTTP rule. Draft:

> 1. **`myclickup` on PATH?** If not, stop — this is a human step. `myclickup` is a
>    personal CLI distributed from the owner's `myclickup` repo (not on PyPI). In the
>    sandbox it is baked into the image, so its absence means the image needs updating;
>    on any other machine, ask the human to clone the repo and install the wheel.
>    Never substitute raw HTTP against the ClickUp API.

Also add one sentence identifying `myclickup` at first mention in each skill (it is
currently referenced throughout the payload without ever being identified or sourced).

**Acceptance:** the string "baked into the sandbox image" appears nowhere under
`plugins/` except as a conditional ("in the sandbox…"); all four copies byte-identical;
all just checks pass.

## WP2 — Close the status-set gap and implement the blocker gate

**Files:** the same 4 ClickUp skill copies; `.myclickup.toml` (this repo);
`templates/.myclickup.toml`.

Two defects, both against the accepted ClickUp-sync design record (ADR-0008,
`docs/adr/0008-clickup-work-sync.md`):

1. **`Complete` cannot be resolved through `[statuses]`.** clickup-report mandates
   "resolve the target status through `[statuses]`, never by hard-coded name", yet
   names `Complete` (and the flow implies `To Do`) while `[statuses]` defines only
   `agent_ready`, `agent_working`, `human_active`, `review`. Add `complete` (and
   `todo` if the flow keeps referencing it) keys to `[statuses]` in **both** this
   repo's `.myclickup.toml` and the template, and reword clickup-report's completion
   section to resolve through the new key. Where the skill *reads* completion state
   (of blockers, of the task), instruct judging by ClickUp's `status_type` field
   (`done`/`closed`), not by name — the design record already mandates this and the
   skills currently only allude to it.
2. **The blocker gate is missing.** The design record's headline rule — *a
   `ClickUp-blocked-by` entry whose live status is not done/closed stops the work, and
   the gate re-reads live* — is stated in `work/README.md` but implemented in neither
   skill. Add to clickup-pull (after front-matter creation): if any blocked-by task's
   status is not done/closed, say so and mark the item blocked rather than handing it
   off as ready. Add to clickup-report (preflight, when transitioning *into* the
   agent-working status): re-read each `ClickUp-blocked-by` task live; a live blocker
   stops the transition — report it instead.

**Acceptance:** clickup-report contains no status name that `[statuses]` cannot
resolve; both skills contain an explicit blocker-gate step citing live re-read;
`work/README.md`'s two rules ("snapshot not mirror", "blocker stops work") each have an
implementing step in a skill; all copies in sync.

## WP3 — Template defaults that contradict the fail-loudly doctrine

**Files:** `templates/.myclickup.toml`; `plugins/myconv/skills/apply-conventions/SKILL.md`.

1. `templates/.myclickup.toml` ships the author's four real status names
   (`"Ready for Agent"` etc.) as live uncommented defaults — exactly the
   wrong-value-resolves-silently failure the file's own header argues against.
   Comment the `[statuses]` values out (or set them empty) with a one-line instruction
   to fill them from the Space's actual statuses; wrong/unset must fail loudly, and
   the skills' case-insensitive-match warnings make silent mismatch a real risk.
2. `templates/.claude/settings.json` sets `"plansDirectory": "./work/plans"`, which
   presupposes the opt-in `work/` tier; JSON carries no comment, and only the
   blueprint (not the skill) says to drop the line when skipping `work/`. Add one
   sentence to apply-conventions step 3 (tier choice): *"If the repo skips `work/`,
   drop `plansDirectory` from the settings template — it points at a directory that
   won't exist."*

**Acceptance:** no real status names as live defaults anywhere under `templates/` or
`plugins/`; apply-conventions mentions the `plansDirectory` coupling; sync checks pass.

## WP4 — apply-conventions argument handling and payload guidance

**File:** `plugins/myconv/skills/apply-conventions/SKILL.md` only.

1. Its frontmatter advertises `[--audit] [path]` but the body never reads
   `$ARGUMENTS`: `[path]` is entirely unimplemented and `--audit` is honoured only by
   one aside. Add a "Mode" section near the top (mirror wrap-up's, which parses its
   flag explicitly): parse `$ARGUMENTS`; a path argument sets the target repo
   (default: current repo); `--audit` means stop after the gap report in step 5.
2. The skill never mentions that its own payload bundles copies of the four shared
   skills at `templates/.claude/skills/`. Add explicit guidance to the
   skills-placement discussion: **when the consumer machine has the `myconv` plugin
   installed, do NOT copy these into the target repo** — namespaced versions already
   load everywhere, and an unnamespaced twin shadows the maintained copy (the exact
   drift that motivated plugin distribution, per the plugin-distribution decision
   record ADR-0007). Copy them only for a consumer who will not have the plugin, and
   say which case applies.
3. Mention `templates/.gitignore` by name where step 3 relies on "gitignored
   `AGENTS.local.md`" (it currently ships silently).

**Acceptance:** body contains `$ARGUMENTS` with defined semantics for both arguments;
placement guidance for the bundled skill copies exists; `just sync-plugin` + checks pass.

## WP5 — Shop-window staleness and manifest hygiene

**Files:** `.claude-plugin/marketplace.json`; `plugins/myconv/.claude-plugin/plugin.json`;
`README.md`; `CHANGELOG.md`.

1. `marketplace.json`'s plugin description names only make-plan and wrap-up; the
   plugin ships five skills. Rewrite to name all five (this is the description a
   user reads at install time).
2. `README.md` (~line 37) likewise lists three of five — add the two ClickUp skills.
3. `plugin.json`: add `repository` (and `homepage` if sensible) pointing at the
   conventions repo — four payload files cite "the conventions repo" by decision-record
   number, but nothing in the payload identifies where that repo lives. Consider
   dropping `displayName` (not a documented manifest field; `name` is what's shown).
4. Fold a line into the `0.1.0 — unreleased` CHANGELOG entry covering the
   consumer-visible wording changes from WP1–WP4.

**Acceptance:** `just validate` passes; every skill the plugin ships is named in the
marketplace description and README install section; `plugin.json` identifies the source
repo.

## WP6 — justfile blind spots

**File:** `justfile`. Constraint: this tooling operates only inside this repo and
mutates no consumer — keep it that way (boundary set by the reference-not-automation
decision, ADR-0001, restated in ADR-0007). Note: WP7 re-plumbs `sync-plugin` and
retires `check-skill-mirrors`; do WP6 after WP7 or as part of it.

1. **Derive the shared-skill list dynamically** (glob `.claude/skills/*/` — the
   post-prune canonical home) in `sync-plugin` and `check-plugin-sync`. Today the four
   names are hardcoded; a fifth shared skill would be silently under-synced while
   every check stays green — the most likely future drift.
2. **Add the payload-link rule as a recipe** (`check-plugin-links`:
   `! rg '\]\(\.\./' plugins/`) — the repo's AGENTS.md names this grep as the catcher
   but it is manual today.
3. **Add a version-agreement check**: `plugin.json` version == `marketplace.json`
   version (nothing enforces it; the next bump will desync them — the repo's own
   AGENTS.md names only `plugin.json`).
4. **Add an aggregate `just check`** running all of: check-plugin-sync,
   check-plugin-links, the version check, check-vendored (WP7.6, skips when
   unconfigured), validate.

**Acceptance:** `just check` exists and passes; temporarily adding a dummy fifth skill
folder under `.claude/skills/` makes `check-plugin-sync` fail until synced (test this,
then remove the dummy).

## WP7 — The prune: collapse the skill copies to one home per role (DECIDED — execute FIRST)

Decided 2026-08-12: option (b), adopted by the deployment owner via
`handoff-myconv-skill-prune.md` (in this folder — read it before executing; it is the
authority on the deployment tier). Target state, one home per role:

| Role | Home | Owner |
|---|---|---|
| Canonical | `.claude/skills/` (this repo) | this repo |
| Product | `plugins/myconv/` | this repo, synced from canonical |
| Deployment | container `~/.claude/skills/myconv/` | windows-ai-sandbox — NOT this repo |

The deployment copy is the end of a vendoring chain: `plugins/myconv/` → (manual
`just sync-skills` in windows-ai-sandbox) → its `sandbox_templates/skills/myconv/`
(rev pinned in that repo's UPSTREAM.md, currently 3f60422) → (converge on every
profile `up`) → host profile cache → bind mount into the container. Hand-editing the
container copy is reverted by design. The staleness observed in the audit is
upstream-head vs vendored rev, not a sandbox fault — the fix is landing this WP, then
the human re-vendors.

Steps (all inside this repo; the handoff's constraints apply):

1. **Delete `templates/.claude/skills/`** (the "genericised mirror" tier — it was a
   byte-copy fiction; the audit confirmed zero genericisation).
2. **Delete `plugins/myconv/skills/apply-conventions/templates/.claude/skills/`**
   (the payload-embedded copies — they register as phantom scoped skills and, via the
   vendored seed, currently ride into every profile).
3. **Re-plumb the justfile**: `sync-plugin` copies `reference/` and `templates/` as
   before (templates now skill-less) and syncs `.claude/skills/*/` (glob, per WP6.1)
   → `plugins/myconv/skills/`. Retire `check-skill-mirrors`; `check-plugin-sync` now
   compares canonical skills vs payload skills plus root `reference/`+`templates/` vs
   payload copies.
4. **Rewrite apply-conventions' skill-delivery guidance**: skills are delivered by the
   plugin (marketplace-installed or sandbox-seeded), **never pasted into a consumer
   repo** — retiring pasted copies as a concept. "Place the two ClickUp skills" (step
   4) becomes "confirm the plugin is available and the tracker pin set"; the
   `.claude/skills/` bullet in the tier list stays (consumers may write their OWN
   repo-local skills) but no longer implies copying these four.
5. **Bump the version 0.1.0 → 0.2.0** in `plugin.json` AND `marketplace.json`, with a
   matching CHANGELOG entry (the payload shape changed: embedded skill copies
   removed). Adopt the discipline: any payload change bumps the version — the
   sandbox's UPSTREAM.md pins the rev, but the version field is what's visible
   in-container.
6. **Add `check-vendored`** (replaces the earlier `check-seeded` idea): diff
   `plugins/myconv/` against the sandbox repo's `sandbox_templates/skills/myconv/`,
   locating that path via a gitignored local pointer file or env var; **skip with a
   notice when unconfigured**. Never diff against `~/.claude/skills/myconv/` — that
   is a derived cache two steps removed and may legitimately be mid-convergence.
7. **Keep `plugins/myconv/` and its `.claude-plugin/plugin.json` marker exactly where
   they are** — the sandbox sync script keys plugin discovery on that shape; renaming
   or restructuring breaks the vendoring silently.
8. **Update repo docs** that name the deleted tier: `README.md` (templates list
   includes `.claude/skills/`), `AGENTS.md` if it references skill mirrors, and the
   `check-skill-mirrors` mentions in AGENTS.md's "how to move forward".
9. **Hand back to the human**: after the commit, the re-vendor is theirs —
   `just sync-skills` in windows-ai-sandbox, then `profile.sh <p> reset-skills` (or
   next `up`). Sandbox-side acceptance: in-container list shows exactly one copy of
   each myconv skill at 0.2.0, no phantom nested `make-plan`/`wrap-up`.

**Acceptance (in-repo):** no `SKILL.md` exists under `templates/` or under
`plugins/myconv/skills/apply-conventions/templates/`; `just check` passes;
`rg -l 'SKILL.md' plugins/` finds exactly the five real skills; versions agree at
0.2.0; CHANGELOG entry present.

## WP8 — Remaining open items (decided-in-principle or awaiting the owner)

1. **CLI-first boundary (decided: hold).** clickup-pull hand-encodes mechanisms
   (subtask discovery, dependency-direction split, hidden-folder path fix) that the
   `myclickup` dev tree already implements natively. Decision 2026-08-12: hold the
   skills at CLI 0.2.0 until the owner iterates the CLI once more and the sandbox
   image re-vendors it; then open a small work item rewriting pull/report to lean on
   the CLI — mechanism in the tool, policy in the skill. Do not pre-empt.
2. **Ecosystem intersection (decided 2026-08-12).** One action is in scope NOW:
   add `disable-model-invocation: true` to clickup-report's frontmatter (it writes to
   a live tracker — human-invoked only; this also removes its description from the
   model's ambiguity pool). Fold into the WP1/WP2 edits. Everything else —
   description sharpening, declaring `myconv:make-plan` the planning entry point,
   grafting superpowers' `writing-plans` content, broader library intersection — is
   deferred to **work/0012-skill-development/**, which carries the full ecosystem
   research and notes.
3. **Generic skill names** (`make-plan`, `wrap-up`): no observed collisions; renaming
   is breaking; default is accept. Naming call stays with the owner.
4. **`templates/AGENTS.md` names `windows-ai-sandbox`**: that repo is public, so this
   is polish, not a leak — genericise to `<your-sandbox-tool>` at will. Cross-repo
   note (owner's request 2026-08-12): windows-ai-sandbox is and stays an open repo;
   a no-personal-data scan (ClickUp IDs, workspace names, emails, real paths) belongs
   in THAT repo's audit tooling — flagged there, not actioned here.

## Validation plan (after WP1–WP6)

```
just sync-plugin
just check          # new aggregate from WP6 (or the four checks individually)
git diff            # review before committing
```

Plus: `rg -n "baked into the sandbox image" plugins/ .claude templates` must show only
conditional wording; `rg -n "Complete" .claude/skills/clickup-report/SKILL.md` must show
it resolved via `[statuses]`.

## Risks

- Until WP7 lands, the four shared skills exist in four byte-identical copies; any WP
  editing them before the prune must edit root + template mirror and re-sync, or
  checks fail. (That failing is the system working.) After WP7 there is one canonical
  copy and `just sync-plugin`.
- WP7 step 7 is load-bearing: the sandbox vendoring keys on the `plugins/myconv/` +
  `.claude-plugin/plugin.json` shape. Restructuring it breaks deployment silently.
- The seeded container copy stays stale until the human re-vendors (WP7 step 9); do
  not "fix" it by editing `~/.claude/skills/myconv/` — convergence reverts it.
- WP2's `[statuses]` additions touch this repo's real pinned config — the new
  `complete` name must match the Space's actual status (verify with
  `myclickup status` / the cache before committing; the audit found the cached Space
  already has `complete`, type `done`).
- Do not touch `docs/adr/` — nothing here supersedes an accepted decision; WP7 items
  would, which is why they're gated.
