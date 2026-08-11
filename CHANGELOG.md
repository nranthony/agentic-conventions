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

## 0.1.0 — unreleased

First packaged release ([ADR-0007](docs/adr/0007-plugin-distribution.md)). Not yet published
to a remote, so no consumer has this version.

### Added

- **`/myconv:apply-conventions`** — sets up or audits a repo against the blueprint. Carries
  the full `reference/` write-up and all eleven `templates/` files as bundled payload, so it
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
