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
