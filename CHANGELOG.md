# Changelog

**Scope: what a consumer receives.** This file tracks changes to the `myconv` plugin's
user-visible surface — its skills, the bundled blueprint, and the templates — so that a
version bump in `plugins/myconv/.claude-plugin/plugin.json` means something to someone who
cannot read this repo's history. `claude plugin list` shows the version; this says what
changed in it.

It deliberately does **not** track internal churn. Decisions live in [docs/adr/](docs/adr/),
in-flight work in [work/](work/), and everything else in the commit log. If a change doesn't
alter what an installed or seeded consumer gets, it does not belong here.

Versions follow the `version` field in `plugin.json`. Newest first.

---

## 0.7.0 — unreleased

A repo's own rules about what may be committed now beat a shared skill's instruction to
write it — in both directions. And, generalising that: a shared skill states what it does
when a repo has a thing and what it says when it does not, never what a repo must contain
(ADR-0015). Where it cannot find something, it says which paths it checked.

### Changed

- **`/myconv:clickup-pull` defers to a repo's content rules.** Where a repo's `AGENTS.md`,
  an ADR, or a stated policy limits what may enter tracked files, that rule now wins over
  the skill's own instructions: the slug derives from the kind of work rather than the task
  title, `## From ClickUp` becomes a restatement **labelled as de-identified**, and the same
  test applies to every front-matter field carrying a title or a path (`ClickUp-parent`,
  `ClickUp-blocked-by`, `ClickUp-blocks`, `ClickUp-related`, `ClickUp-path`). The
  `ClickUp:` id and URL are always kept — a pointer identifies nothing on its own, and
  without it the restatement cannot be checked. Dropping a relation to a bare ID is
  explicitly not the way out. A deliberately de-identified section is **not** drift on
  re-pull. Repos with no such rule are unaffected. **From the `legal` repo's report of
  2026-08-25** (`clickup-pull`, `assumed-repo-shape`) — ADR-0014.
- **`/myconv:clickup-pull` reads the repo instead of asserting a shape.** It required a pinned
  `[statuses]` table, hard-coded `proposal.md`, and showed a bare front-matter block — while,
  one sentence away, deferring to "the repo's own proposal template headings". Now a missing
  status-role table is a **state, not an error**: a caller-supplied status name is validated
  against the live list, recorded in the item and the handoff as **supplied-not-pinned**, and
  this stays **read-path only** — `/clickup-report` still requires a pin or an explicit
  confirmation of the exact name. The filename follows the repo's own `work/README.md` and
  existing items, defaulting to `spec.md` for a pulled task **and saying that it did**;
  front-matter is pinned **under the `#` title**; and a search that finds nothing names the
  paths it checked rather than passing quietly. From `work/0018` Group A, opened from
  `myclickup`'s consumer feedback — ADR-0015.
- **`/myconv:clickup-pull` no longer skips in silence.** Comments are always read
  (`myclickup comments <id> --json --live`), with the count and last-commented date recorded
  **even when there are none**, so "checked, nothing there" stops reading like "never looked".
  Attachments get a `## Attachments` body section — title, mimetype, size, version, the ClickUp
  date, the pulled-date, and the reason anything was left behind, but **never the signed URL**,
  which would put an expiring credential in a tracked file. A download's `skipped` array is
  reported rather than swallowed: a skip is not a pass. From `work/0018` Group B; the
  auto-download gate itself stays deferred, still waiting on a CLI selector and an egress
  allow-list entry.
- **`/myconv:clickup-report` applies the same rule to what leaves the repo.** A tracker is
  third-party and shared, and a comment cannot be unpublished, so the restriction binds
  harder there than on a committed file: a status transition is always safe (it carries a
  role name and no content), and an exception comment names the *shape* of a hurdle rather
  than its content. Nothing enforces this — the `ask` permission tier and the mandatory
  dry-run already put a human on the exact text; the skill now says what to look for.
  ADR-0014.
- **`/myconv:report-skill-feedback` routes to the repo that *owns* the skill.** Step 2
  sent every report to the conventions repo, which is wrong for any skill it does not own
  — a tool that ships its own vendored skill owns that one, and a report filed where the
  text cannot be edited is a report nobody can action. The owner is the repo the skill
  ships *from*; a channel's `manifest.toml` names it. The destination is now a **tracked
  `feedback/`** rather than a gitignored doorbell, so reports are archived after triage
  instead of deleted — which is what makes the envelope's own "three reports of one
  friction are a signal" checkable for the first time. `Install mode` gains a decision
  rule, after two independent reporters mis-picked it the same way on day one. ADR-0016,
  amending ADR-0013. **From `depot`'s report of 2026-08-25** (`wrong-path`).
- **`/myconv:wrap-up` reviews held work, not just active and finished.** §6 had two
  cases — done and in flight — so an item that is *neither* was skipped by default: its
  status line says the pause is deliberate, which reads as nothing to do. A held plan
  referencing something the thread just deleted is not paused any more, and its own label
  is what hides that. Worded around the state rather than a status name, so it stays
  correct whatever vocabulary a repo uses. From `work/0014` #7, opened host-side from a
  real `wrap-up` run.
- **`/myconv:wrap-up` says what it could not check.** Discovery was name-based, so a tier
  present under a name the skill did not know read as absent — and one of its own eleven
  sections silently did not run on the repo that reported it. §0 now has three states, not two:
  not kept, kept under another name (read the index, report the mapping you inferred), and
  **could not locate — naming the paths checked**. It prints a tier map before §1 and repeats
  it with the summary, because a report listing only what passed reads as full coverage. Two
  new sections: the repo's **own change gate**, whose clauses are *enumerated and checked, not
  run*, and a **corrected-fact sweep** for a fact this thread fixed in one file and left
  standing in three — bounded to documentation and instruction surfaces, with a capped report
  rather than every hit. The architecture section now covers the enumerations a map carries
  (file lists, counts, command inventories), write-back destinations are ranked (ADR >
  architecture doc > `AGENTS.md` > skill) with the anti-pattern named — a durable fact whose
  only home is a commit message is lost — and the skills section is path-agnostic, degrading to
  the index entry where a guide carries no frontmatter. It also says outright that it is **not
  a substitute for the repo's own gates**. From `work/0014` #1–#6 and #8 — ADR-0015.
- **The `work/` template pins where front-matter goes.** `templates/work/README.md` now states
  that the `- Key: value` block sits under the `#` title, never above it — it is the part read
  by machine later, and a fenced example alone left that to taste. From `work/0018` item 3.

## 0.6.0 — unreleased

The feedback channel ships: a sixth skill owns the report envelope, every other skill
points at it, and every shipped skill now says which text it is.

### Added

- **`/myconv:report-skill-feedback`** — file a report when a shared skill's
  instructions were wrong, stale, or a bad fit for the repo they ran in, or when the
  skill you needed didn't exist. One-way by design: a report must be actionable on
  arrival with no reply, and none is guaranteed. The skill owns the envelope (which
  text ran via the `VERSION` sidecar, which artifact is actually wrong, the step
  quoted by heading, a proposed edit rather than a description, a verdict with
  repo-shape evidence, a risk class drawn by effect) and the transport (tracked
  original in the reporter's repo; a doorbell copy in the conventions repo's
  `inbox/`). Decision record ADR-0013
  (`docs/adr/0013-skill-feedback-channel.md` in the conventions repo): reporter
  proposes, a triage agent collates and assesses, a human approves before anything
  direction-setting is signed. Grew from two reports hand-carried across repos in two
  days (work/0017, work/0018).
- **Every other skill carries a two-line pointer to it** at the top — file at the
  moment you deviate, before working around — and `/myconv:wrap-up`'s skills section
  gains the safety-net sweep: "did any skill mislead this thread?"

- **A generated `VERSION` sidecar in every payload skill directory** — one line,
  plugin version plus a short hash of that skill's `SKILL.md`, written by
  `just sync-plugin` and freshness-checked by `just check` (a stamp can never claim
  text it isn't). Every copy — installed from the marketplace, seeded into a
  container's agent home, or vendored — self-identifies with no runtime path
  discovery. This is the provenance half of the skill-feedback channel
  (work/0017 §2 in the conventions repo): a report that says which text ran skips
  the "was this fixed upstream weeks ago?" round trip. Independently, it answers
  "which version am I running?" for any consumer, which until now took comparing
  file contents against the channel by hand.

---

## 0.5.0 — unreleased

Work items are archived on exit, never deleted. The blueprint's exit rule loses its
delete branch, and no skill will propose removing one. Also: environment notices must
name the ask rather than a host-side mechanism, and the managed sandbox-notice block is
now verified read-only instead of skipped.

### Changed

- **The blueprint's environment-notice section gains a fourth content rule: name the
  ask, not the host-side mechanism.** A human step is discharged outside the sandbox,
  so the notice says who to ask, never how the human does it on the host — a host-side
  script or a path in the sandbox tool's own checkout resolves against the wrong tree
  in every repo the notice ships in. The test is frame of reference: everything a
  notice names must resolve where the reading agent stands, which keeps absolute
  in-sandbox paths and service hostnames legal. From a consuming agent's report in the
  `numerai` repo (2026-08-19), which traced a dead `scripts/with-egress.sh` reference
  in a live notice to the gap: rule 2 ("reframe every denial as a human step") was
  satisfiable by naming a host-only escape hatch.
- **"Never edit inside the sandbox-notice markers" no longer implies "never look
  inside them."** The blueprint's ownership rules, its brownfield gap-map phase, and
  `/myconv:apply-conventions` step 1 now say the same thing: resolve every path and
  named script `AGENTS.md` cites, *including* inside the managed markers — read-only.
  A dead reference there is still a dead instruction; it is reported upstream to the
  sandbox tool, never edited in place. Same report: the audit found the dead path only
  by checking what the ownership rule had implicitly excused.

- **The `work/NNNN-slug/` exit rule is now single-branched** across the bundled blueprint
  (`reference/agentic_native_repo_scaffold.md`), the templates (`templates/work/README.md`,
  `templates/AGENTS.md`), and the planning and wrap-up skills: distil anything durable out,
  then move the folder to `work/archive/`. The former escape hatch — delete the folder if
  nothing durable remains — is withdrawn. "Nothing durable remains" is a prediction about
  future readers rather than something the closing agent can check, and the two outcomes
  are not comparable: archiving costs a directory entry, while a wrong delete destroys the
  record silently and often with no commit behind it to recover from. It also punched
  unreadable holes in a sequence that promises numbers are never reused. Rationale in
  decision record ADR-0012 (`docs/adr/0012-work-items-archive-never-delete.md` in the
  conventions repo), which amends the exit-rule clause of ADR-0006 and leaves the rest of
  that decision standing.
- **`/myconv:wrap-up` will no longer offer deletion as a way to close out a work item.**
  Its end-of-thread `work/` section previously read "move to `work/archive/` — or delete it
  if nothing durable remains"; it now archives, and says so explicitly.
- Every other deletion rule in the conventions is untouched: the `inbox/` doorbell is still
  read-then-deleted once distilled, `work/plans/` is still gitignored scratch, and the
  ClickUp write path still has no delete verb at all.

---

## 0.4.0 — unreleased

The "gloss before you cite" golden rule now covers project shorthand, not just identifiers.

### Changed

- **The gloss-before-cite golden rule in `templates/AGENTS.md` widened to cover shorthand**
  — plan-item letters, table codes, question numbers, codenames — and not only identifiers
  with a canonical home. "R3 shipped" is clear to whoever coined it and opaque to everyone
  else, including the next agent in a fresh session: unlike a decision number, `R3` is
  often not greppable at all, since it resolves only against *which* plan or *whose* table.
  Ordinary technical vocabulary is untouched — "wheel", "rebase" and "manifest" are already
  the plain terms — and when the line is unclear, the rule is to gloss, because
  over-glossing costs a few words while under-glossing costs the reader the whole point.
  Still advice, and now less lintable than before: ad-hoc codes have no pattern to match
  ([ADR-0011](docs/adr/0011-gloss-shorthand.md), extending
  [ADR-0010](docs/adr/0010-gloss-before-cite.md)). The rule remains one line item in Golden
  rules, carrying a worked example for each half.

---

## 0.3.0 — unreleased

The two ClickUp skills are now CLI-first: mechanism lives in `myclickup`, policy stays in
the skill. (The version match with the CLI is coincidence — the plugin and the CLI are
versioned independently.)

### Changed

- **`/myconv:clickup-pull` and `/myconv:clickup-report` require `myclickup` 0.3.0 or
  newer**, and both preflight on `myclickup --version` before doing anything else. Older
  CLIs lack the `subtasks` and `set-status` commands and the derived fields the skills now
  read, and the failure would otherwise look like a task with no relations rather than an
  out-of-date tool.
- **The skills use the CLI's own commands instead of reconstructing them.** Subtasks come
  from `subtasks <id>`; blocked-by/blocks come from the payload's derived `blocked_by` and
  `blocks` arrays; `ClickUp-path` comes from its derived `path`; the status transition is
  written with `set-status`, which sets that one field and validates the name against the
  list's statuses before sending; `statuses --list` answers what a list defines. Reads name
  `--live` or `--cached` explicitly rather than describing cache behaviour.
- **The workaround prose is gone.** The whole-list scan filtered on `parent`, the
  `task_id`/`depends_on` direction table, and the `hierarchy.json` / `folder: "hidden"`
  path fix were 0.2.0-era workarounds; each is now one flag or one field. Policy is
  untouched — one item per child, ask before a large fan-out, read each child's own payload
  (its `subtasks` summary carries no derived relations), blockers gate the work, dry-run
  every write, and only a status change or a short comment ever crosses.
- **The empty-`workspace_id` behaviour is corrected in both `.myclickup.toml` files and in
  the pull preflight.** Under 0.2.0 an empty pin failed with `HTTP 400`; under 0.3.0 it
  falls back to the token's *first* workspace with a warning, exactly like an absent key —
  so an unpinned repo now reads a real board that is merely the wrong one, instead of
  erroring. Ship it empty and fill it in; never guess an ID, since a wrong-but-authorized
  one still resolves silently.

---

## 0.2.0 — unreleased

The payload shape changed: the plugin no longer carries copies of its own shared skills.

### Added

- **A "gloss before you cite" golden rule in `templates/AGENTS.md`** — when writing for a
  human, state what a decision was in plain language and put its identifier in parentheses
  after it, rather than leading with a bare `ADR-0001`. Resolving an ID is a grep for an
  agent and a context switch for the reader, so the cost belongs on the writer's side. It is
  advice, not a check: a glossed line still contains the identifier, so nothing mechanical
  can tell the two apart ([ADR-0010](docs/adr/0010-gloss-before-cite.md)).

### Removed

- **The embedded skill copies under `templates/.claude/skills/`** — `make-plan`,
  `wrap-up`, `clickup-pull` and `clickup-report` were bundled a second time inside the
  `apply-conventions` payload, as material to paste into a consumer repo. They registered
  as phantom scoped skills wherever the plugin was seeded, and an unnamespaced pasted twin
  shadows the maintained copy — the drift plugin distribution exists to prevent
  ([ADR-0007](docs/adr/0007-plugin-distribution.md)). There is now one home per role: the
  conventions repo owns the canonical skills, this plugin is the product, and the
  container's agent home is a derived deployment copy.

### Changed

- **`/myconv:apply-conventions` no longer places shared skills in the target repo.** Skills
  are delivered by the plugin — marketplace-installed or seeded — so the skill now says to
  confirm the plugin is available and the tracker pin set, instead of copying files. A
  repo's own `.claude/skills/` stays in the blueprint for the procedures *that repo* writes
  about itself.
- **The ClickUp skills' preflight now works off the sandbox.** It identifies `myclickup` as
  a personal CLI from the owner's repo (not on PyPI) and, outside the sandbox, asks the
  human to clone and install the wheel instead of declaring installation impossible. The
  never-fall-back-to-raw-HTTP rule is unchanged.
- **The blocker gate from [ADR-0008](docs/adr/0008-clickup-work-sync.md) is implemented.**
  `/myconv:clickup-pull` re-reads each `ClickUp-blocked-by` task after creating the item and
  marks the item blocked rather than presenting it as ready; `/myconv:clickup-report`
  refuses to transition into the agent-working status while a blocker is live. Both judge
  "finished" by ClickUp's status `type` (`done`/`closed`), never by name.
- **`[statuses]` gains a `complete` key**, so `/myconv:clickup-report` can resolve the
  terminal status through the table as its own rule requires — previously it named
  `Complete` literally, which no `[statuses]` entry could resolve. Repos with an existing
  `.myclickup.toml` should add the key.
- **`templates/.myclickup.toml` no longer ships live status names.** The `[statuses]` values
  are commented out as examples with an instruction to fill them from the Space's actual
  statuses: an unset role fails loudly, where an inherited-but-wrong name matches nothing
  and looks like an empty queue.
- **`/myconv:clickup-report` is human-invoked only** (`disable-model-invocation`). It is the
  one skill that writes to a live tracker, so it no longer runs on the model's initiative.
- **The marketplace description and the README install section name all five skills.** Both
  still advertised only the planning pair, so a user reading the catalog at install time had
  no idea `apply-conventions` or the two ClickUp skills came with it. `plugin.json` now also
  carries a `repository` field: several payload files cite "the conventions repo", and
  nothing installed alongside them said where it lives.
- **`/myconv:apply-conventions` implements its advertised arguments.** A path argument now
  sets the target repo (default: the current one) and `--audit` is defined as stop-after-the
  gap-report; it also names `templates/.gitignore` as the source of the `AGENTS.local.md`
  ignore rule, and says to drop `plansDirectory` when the repo skips `work/`.

---

## 0.1.0 — unreleased

First packaged release ([ADR-0007](docs/adr/0007-plugin-distribution.md)). Not yet published
to a remote, so no consumer has this version.

### Added

- **`/myconv:apply-conventions`** — sets up or audits a repo against the blueprint. Carries
  the full `reference/` write-up and every `templates/` file as bundled payload, so it
  works in a repo with no checkout of this one present. Supports `--audit` to report the gap
  without writing.
- **`/myconv:make-plan`** and **`/myconv:wrap-up`** — the shared planning and end-of-thread
  procedures, previously available only where this repo was checked out.
- **Marketplace catalog** (`.claude-plugin/marketplace.json`), making this repo installable
  with `/plugin marketplace add` + `/plugin install myconv@agentic-conventions`.
- **Seeded delivery for closed-egress containers** — copying `plugins/myconv/` into a
  profile's `~/.claude/skills/` loads it as `myconv@skills-dir` with no network and no
  install step, covering every repo in that profile's workspace.
- **`/myconv:apply-conventions` now settles the tracker link explicitly.** It asks whether
  the repo's work is tracked in ClickUp and, if so, for the workspace ID and scope to write
  in — rather than leaving a half-configured pins file behind. A repo with no link gets
  neither the file nor the ClickUp skills, so nothing dead is placed.
- **`/myconv:clickup-pull` and `/myconv:clickup-report`** — pull a ClickUp task into a
  `work/NNNN-slug/` item, and report status changes or short hurdle comments back. The
  pull is read-only against ClickUp; the report dry-runs every write first. Both require
  the `myclickup` CLI and a repo-root `.myclickup.toml` with a pinned workspace, and stop
  with a plain message when either is missing — so they are inert in repos that don't use
  a tracker.
- **External-tracker guidance in the blueprint** ([ADR-0008](docs/adr/0008-clickup-work-sync.md))
  — a tracker and `work/` are two projections of one item, not competing homes, so the
  blueprint no longer tells you to skip `work/` when a tracker is in use. Adds the
  partial-sync rule (pull intent in; push back only status and short comments; plans and
  notes cross neither way) and a provenance-table row. Defines what a **tracker link**
  actually is — a property of the repo with one test, the committed pins file and whether
  its ID is filled in — so "no tracker link" has a checkable meaning rather than being a
  vibe.
- **`templates/.myclickup.toml`** — opt-in, non-secret tracker pins with `workspace_id`
  deliberately **empty**. An empty pin fails loudly on use; a defaulted one resolves
  silently against another workspace's board. Carries `[work_sync].scope` for repos that
  own only a corner of a shared workspace, and a semantic-role → status-name map.
- **A `validation/` tier in the blueprint, plus `templates/validation/`**
  ([ADR-0009](docs/adr/0009-validation-evidence-tier.md)) — an opt-in home for *evidence*: a
  committed, dated record of how a system performed against a labelled corpus, which a CI gate
  reads. It is a category the other tiers cannot hold, most decisively `work/`, whose exit rule
  archives completed items while an artifact a build depends on can never be archived.
  Authority is encoded in the filename — hand-edited `expected.json` is what the gate enforces,
  regenerated `measured.json`/`.md` is what the last run produced — so regenerating a record
  can no longer change what passes, and loosening a threshold becomes a one-line diff with a
  required `why` beside it. Every threshold carries that justification; every record carries a
  `provenance` block naming the command, commit and corpus version that produced it. Ships as
  convention, not machinery: no CI check, no `CODEOWNERS` requirement.
- **`templates/.gitignore` ignores `.cache/`** — tool snapshot caches are regenerable and
  can carry customer-identifying names (a ClickUp cache holds space and list titles). The
  cache directory is created by ordinary read commands, not just an explicit sync, so an
  adopting repo would otherwise pick it up as untracked content.

### Changed

- Skills are now **namespaced**: `/wrap-up` becomes `/myconv:wrap-up`. Anyone carrying
  hand-copied unnamespaced skills in `~/.claude/skills/` should remove them — a stale twin
  shadows the maintained copy, which is the drift that motivated ADR-0007.

### Fixed

- The bundled blueprint no longer contains a relative link that escapes the plugin payload.
  An installed plugin cannot read outside its own directory, so the previous `ADR-0004`
  cross-reference resolved nowhere for every consumer.
- `templates/CODEOWNERS` no longer ships real owner handles. A copied `CODEOWNERS` naming a
  real person silently gates every PR in the adopting repo on someone who isn't watching.
