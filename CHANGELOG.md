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

## 0.5.0 — unreleased

Work items are archived on exit, never deleted. The blueprint's exit rule loses its
delete branch, and no skill will propose removing one.

### Changed

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
