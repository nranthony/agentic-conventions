# Proposal: Plugin distribution — one payload, two delivery paths

- Status: Accepted → [ADR-0007](../../docs/adr/0007-plugin-distribution.md)
- Author: nranthony + agent
- Supersedes the deferral in `work/0003-skills-beyond-this-repo/proposal.md` §5
- Implemented 2026-08-10: `plugins/myconv/`, `.claude-plugin/marketplace.json`, `justfile`.
  Sandbox rollout is handed off in [sandbox-handoff.md](sandbox-handoff.md).

## Summary

Package this repo's shared skills **and its blueprint** (`reference/` + `templates/`) as a
Claude Code **plugin**, with this repo doubling as its own plugin marketplace. One payload,
two delivery paths:

- **A — networked machines:** `/plugin marketplace add` + `/plugin install`, versioned and
  refreshable.
- **B — sandbox profiles (closed egress):** host-side copy of the plugin directory into the
  profile's persistent `claude-home/skills/`, where it auto-loads as
  `agentic-conventions@skills-dir` in **every repo under that profile's mapped workspace** —
  no network, no install step, no image rebuild.

Both paths deliver identical bytes. Nothing mutates a target repo: the plugin carries a skill
that *instructs an agent* to apply the conventions with judgment, which is the artifact
[ADR-0001](../../docs/adr/0001-reference-not-automation.md) says this repo should produce.

## Motivation

Three forces, two of them new since [ADR-0006](../../docs/adr/0006-proposals-are-work-items.md):

1. **Multiple machines.** The conventions are only usable where this repo is checked out.
   `work/0003 §5` deferred plugins with an explicit trigger — *"a second machine or
   collaborator consuming these skills"*. That trigger has fired.
2. **Cross-repo within one sandbox profile.** A sandbox profile maps a *workspace* — a parent
   or company directory containing many repos — and sees nothing outside it. The capability
   is wanted in every repo under that workspace, not vendored into each one by hand.
3. **Hand-vendoring has already drifted.** Measured on the current machine
   (2026-08-10): the hand-copied `~/.claude/skills/` pair has diverged from the repo —
   `make-plan` by 6 lines, `wrap-up` by 34 (122 seeded vs 126 in repo). Both differ from
   `templates/` and `.claude/` by the same amount, so the repo copies agree and the seeded
   pair is simply stale, with nothing surfacing that fact. This is the failure the
   [distribution doc](../../docs/distributing-skills-downstream.md) predicted
   ("vendored copies drift from upstream until re-synced") arriving in practice.

## Proposal

### The payload

```
agentic-conventions/
├── .claude-plugin/marketplace.json        # NEW — catalog at repo root
└── plugins/agentic-conventions/
    ├── .claude-plugin/plugin.json         # name, version, description
    └── skills/
        ├── apply-conventions/
        │   ├── SKILL.md                   # "read the blueprint, apply with judgment"
        │   ├── reference/                 # generated copy — 1 file, 387 lines
        │   └── templates/                 # generated copy — 11 files, 395 lines
        ├── make-plan/SKILL.md
        └── wrap-up/SKILL.md
```

Total payload ≈ 780 lines / 12 files. An installed plugin **cannot read files outside its own
directory** — paths traversing out (`../templates`) are not copied into the cache — so the
blueprint must physically live inside the plugin to travel with it.

Root `reference/` and `templates/` stay canonical and browsable; a `just sync-plugin` recipe
copies them into the plugin tree. Note this is not a *new* duplication: `reference/` already
inlines four of the eleven template files as fenced blocks in its "Starter templates" section,
maintained by hand. The recipe should eventually cover that too.

### Delivery path A — marketplace (networked machines)

A marketplace is just a git repo containing `.claude-plugin/marketplace.json`. Consumers:

```
/plugin marketplace add <owner>/agentic-conventions
/plugin install agentic-conventions
```

Gets versioning (`version` in `plugin.json` gates updates), `/plugin marketplace update`, and
enable/disable. **Human prerequisite:** the remote must exist and be pushed — remote git is
denied to the agent, so every rollout of this path has a human in it.

### Delivery path B — sandbox seed (closed-egress profiles)

Any folder under a skills directory containing `.claude-plugin/plugin.json` loads as a plugin
named `<name>@skills-dir` on the next session — **discovered in place, no marketplace, no
install, no network**. At `~/.claude/skills/` it is *personal scope*: loads in every project,
no workspace-trust dialog, no restrictions on its components.

That maps exactly onto the sandbox's durability model: `~/.claude` is a per-profile host bind
mount that persists across container recreates and is placeable from the host before the
container starts. The durable artifact is a file in the agent home — never an installed
binary, never anything in `/opt` or a `noexec` tmpfs.

```
<profile>/claude-home/skills/agentic-conventions/     ← host-side copy of plugins/agentic-conventions/
    ├── .claude-plugin/plugin.json
    └── skills/{apply-conventions,make-plan,wrap-up}/
```

This rides the sandbox's **existing** `ensure_state` seeding loop and `reset-skills` refresh —
the same mechanism already copying `skills/*` into each profile's `claude-home/`. Per the
[distribution doc](../../docs/distributing-skills-downstream.md), the refresh script itself
lives in the **sandbox repo**, not here; this proposal only fixes the contract it copies.
The source path stays a gitignored pointer (`CONVENTIONS_DIR`), never a symlink, and the
refresh runs on demand — never during a container build.

**Profile-wide is free; cross-profile is a host loop.** One profile's repos are covered by the
single copy above, because personal scope loads everywhere. Covering *several* profiles means
the host-side script iterates profiles — a fan-out in the sandbox repo, not a design change here.

**Stamp the version.** Set `version` in `plugin.json` even though skills-dir plugins are
discovered rather than installed, so `claude plugin list` shows which vintage a profile is
carrying. That makes the drift measured above *visible* instead of silent, which is the actual
fix for what went wrong.

### Why not symlinks

Symlinks cannot survive all delivery paths: dereferenced on marketplace install, **skipped**
for `--plugin-dir` and local-path installs, and absent entirely from a seeded skills-dir plugin
that loads in place. They also break on Windows/WSL2 checkouts, and the distribution doc already
rejects them — content travels, paths never do.

### ADR-0001 compatibility

Packaging and delivery only. The plugin ships material plus a skill that tells an agent what
shape to aim for; the agent in the target repo decides what applies. Nothing copies files into a
target repo unattended, nothing regenerates a `CLAUDE.md`, nothing force-enables CI — the three
footguns that killed `scripts/apply.sh`. The `justfile` is a *packaging* recipe operating only
inside this repo, never on a consumer.

## Resolved

1. **Namespacing — accepted, with a short prefix.** The namespace comes from `name` in
   `plugin.json` and is independent of the repo name, so the plugin is `myconv` and
   invocations read `/myconv:wrap-up`. All three skills ship in the one plugin rather than
   splitting: they assume the same folder structures, and keeping them aligned is worth the
   longer invocation.
2. **Model invocation stays enabled.** No skill sets `disable-model-invocation`, including
   `apply-conventions`.
3. **The `justfile` lives here**, because it packages this repo's own payload. The sandbox's
   *refresh* script remains the sandbox repo's, per the distribution doc.

## Open questions

1. **Does the sync recipe also regenerate the reference's inlined "Starter templates" section?**
   Currently no — those four fenced blocks stay hand-maintained. Fixing it is in scope for the
   drift problem but turns the recipe from a copy into a templating step.
2. **`~/.claude/CLAUDE.md`** is pre-seedable the same way, but it is global standing
   instructions rather than plugin payload. Treated as out of scope.
3. **`sync-plugin` never deletes** (`rm -rf` is hook-blocked in the sandbox, and a deleting
   sync is a footgun anyway). Stale leftovers surface via `check-plugin-sync` as "Only in …"
   and are removed by hand. Acceptable at this size; revisit if the payload grows.
4. **Should `check-plugin-sync` and `check-skill-mirrors` become a CI gate or a `/myconv:wrap-up`
   checklist line?** Right now they are manual recipes, which is how the last drift went
   unnoticed.

## Alternatives

- **`CLAUDE_CODE_PLUGIN_SEED_DIR`** — the documented container path: build a seed dir, point the
  env var at it, get read-only seed-managed marketplaces. Rejected for this sandbox: the natural
  location (`/opt/claude-seed`) is container-layer and destroyed on recreate, building the seed
  needs `claude plugin install` against the network at build time, and every convention update
  becomes an image rebuild. Path B gets the same result from a file copy into a mount that
  already persists. Revisit if profiles ever need a genuinely read-only, admin-managed toolkit.
- **Plain skills only, no plugin** — what happens today. Keeps `/wrap-up` unnamespaced and is
  zero work, but has no version field, no single unit to refresh, and no way to see staleness.
  It is precisely the arrangement that produced the 34-line drift.
- **Per-repo vendored copies** — the distribution doc's mode 3. Wrong granularity here: it puts
  N copies under one profile's workspace when `~/.claude/skills/` covers all of them with one.
- **npm/zip distribution** — registries are closed in the sandbox and release-asset hosts are off
  the allowlist. A git tree is the only material that arrives without an egress window.
