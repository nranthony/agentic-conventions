# ADR-0007: Distribute the conventions as a Claude Code plugin

- Status: Accepted
- Date: 2026-08-10
- Deciders: nranthony + agent

## Context

Until now the conventions were usable only where this repo is checked out. Three forces
made that untenable:

1. **More than one machine.** [work/0003 §5](../../work/0003-skills-beyond-this-repo/proposal.md)
   deferred plugins with an explicit trigger — "a second machine or collaborator consuming
   these skills". That trigger fired.
2. **Many repos under one sandbox profile.** A profile maps a *workspace* — a parent directory
   holding many repos — and can see nothing outside it. The capability is wanted in every repo
   under that workspace, without vendoring a copy into each.
3. **Hand-vendoring had already drifted.** Measured 2026-08-10: the hand-copied
   `~/.claude/skills/` pair had diverged from the repo — `make-plan` by 6 lines, `wrap-up` by
   34 (122 lines seeded vs 126 in repo) — with nothing surfacing the staleness. This is the
   exact failure [docs/distributing-skills-downstream.md](../distributing-skills-downstream.md)
   predicted for vendored copies.

The constraint that shaped the design: an installed plugin cannot read files outside its own
directory, and symlinks do not survive every delivery path (dereferenced on marketplace
install, skipped for local/`--plugin-dir` installs, absent from a seeded skills-directory
plugin that loads in place). They also break on Windows/WSL2 checkouts.

## Decision

Package the shared skills **and the blueprint** as a single Claude Code plugin, `myconv`,
with this repo doubling as its own marketplace (`.claude-plugin/marketplace.json`).

- **Payload:** `plugins/myconv/` holds `apply-conventions` (carrying generated copies of
  `reference/` and `templates/` as skill payload), plus `make-plan` and `wrap-up`.
- **Canonical sources stay at the repo root**; `just sync-plugin` copies them into the plugin
  tree and `just check-plugin-sync` fails on drift. The generated copies are committed,
  because the marketplace path serves them straight out of git.
- **Delivery path A — networked machines:** `/plugin marketplace add` then
  `/plugin install myconv@agentic-conventions`.
- **Delivery path B — closed-egress sandbox profiles:** the host copies `plugins/myconv/` into
  the profile's persistent `claude-home/skills/myconv/`, where it loads as `myconv@skills-dir`
  — discovered in place, no marketplace, no install, no network. Personal scope means it loads
  in every repo under that profile's workspace.
- **Namespace:** the plugin is named `myconv`, not `agentic-conventions`, so invocations read
  `/myconv:wrap-up`. The namespace comes from `name` in `plugin.json` and is independent of the
  repo name.
- **Model invocation stays enabled** on all three skills; none sets
  `disable-model-invocation`.

This is packaging and delivery only. The plugin ships material plus a skill that tells an agent
what shape to aim for; the agent in the target repo decides what applies. Nothing copies files
into a consumer unattended — [ADR-0001](0001-reference-not-automation.md) holds.

## Consequences

- **Skills become namespaced.** `/wrap-up` is now `/myconv:wrap-up`. Accepted deliberately:
  the three skills are one coherent unit that assumes the same folder structures, and keeping
  them aligned is worth the longer invocation. Any pre-existing unnamespaced copies at
  `~/.claude/skills/make-plan/` and `~/.claude/skills/wrap-up/` must be **removed** when the
  plugin is seeded, or a stale unnamespaced twin shadows the maintained one — which is how the
  drift above happened.
- **The blueprint travels.** An agent in an unrelated repo can run `/myconv:apply-conventions`
  with no checkout of this repo present.
- **A packaging step now exists.** `justfile` is the first build-ish tooling here since
  `scripts/apply.sh` was deleted. It operates only inside this repo and mutates no consumer, so
  it does not reopen ADR-0001 — but the boundary is worth restating whenever it grows.
- **Duplication is now explicit and checkable.** `reference/` already inlined four templates by
  hand; that stays true, but the new copies are machine-generated and drift is detectable via
  `just check-plugin-sync` instead of invisible.
- **`sync-plugin` never deletes.** It copies over the top, so a file removed upstream lingers in
  the plugin tree until removed by hand; `check-plugin-sync` reports it as "Only in …".
- **Path A needs a human.** Remote git is denied to the agent, so publishing and updating the
  marketplace is always a human step.
- **Version stamping matters.** `version` in `plugin.json` is informational for a seeded
  skills-directory plugin, but it makes `claude plugin list` show which vintage a profile
  carries — turning the drift that motivated this ADR into something visible.

## Alternatives considered

- **`CLAUDE_CODE_PLUGIN_SEED_DIR`** — the documented container pre-population path. Rejected for
  this sandbox: the natural location (`/opt/claude-seed`) is container-layer and destroyed on
  recreate, building the seed requires `claude plugin install` against the network at build
  time, and every convention update becomes an image rebuild. A file copy into the already
  persistent `~/.claude` mount achieves the same with none of that. Revisit if profiles ever
  need a genuinely read-only, admin-managed toolkit.
- **Plain unnamespaced skills, no plugin** — the status quo. Keeps `/wrap-up` short and costs
  nothing, but has no version field, no single unit to refresh, and no way to see staleness. It
  is precisely the arrangement that produced the 34-line drift.
- **Symlinks to avoid duplicating the payload** — rejected on mechanics (see Context) and
  because the distribution doc already ruled them out: content travels, paths never do.
- **Per-repo vendored copies** — wrong granularity: N copies under one profile's workspace where
  `~/.claude/skills/` covers all of them with one.
- **npm or zip distribution** — registries are closed in the sandbox and release-asset hosts are
  off the egress allowlist. A git tree is the only material that arrives without an egress window.
