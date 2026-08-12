# Handoff: seeding the `myconv` plugin into sandbox profiles

**Audience:** the agent (or human) working in the `windows-ai-sandbox` repo.
**Upstream decision:** [ADR-0007](../../docs/adr/0007-plugin-distribution.md). Read it if you
need the *why*; this document is the *what*.

**Revision 3 (2026-08-10)** — the sandbox replaced create-only seeding with convergence
(their ADR-0005, see [sandbox-seeding-change.md](sandbox-seeding-change.md)). Step 0 is closed,
step 3 collapses to two actions, `reset-skills` becomes `up`, and a `variants/` strip bug joins
step 6. Revision 2's in-container verification and four corrections are folded in above.
Rounds recorded in [notes.md](notes.md).

**Scope.** Everything below is a change to the **sandbox repo**. The upstream side is done:
the plugin exists, validates, and is committed. Your job is to get it into each profile's
agent home and keep it fresh.

---

## What you are installing

A single directory, `plugins/myconv/`, from the `agentic-conventions` checkout:

```
plugins/myconv/
├── .claude-plugin/plugin.json          # name: "myconv", version 0.1.0
└── skills/
    ├── apply-conventions/
    │   ├── SKILL.md
    │   ├── reference/                  # 1 file,  387 lines
    │   └── templates/                  # 11 files, 395 lines
    ├── make-plan/SKILL.md
    └── wrap-up/SKILL.md
```

~16 files, ~800 lines, all plain markdown and JSON. No binaries, no install step, no network.
Measured cost once loaded: **~8 tokens always-on**.

## The mechanism

Any folder under a **skills directory** containing `.claude-plugin/plugin.json` loads as
`<name>@skills-dir` on the next session — discovered in place, no marketplace, no install. At
`~/.claude/skills/` that is *personal scope*: it loads in **every project**, with no
workspace-trust dialog and no component restrictions. One profile maps one workspace of many
repos, so **one copy covers every repo in the profile.**

Destination is `skills/myconv/`, **not** `plugins/`. `~/.claude/plugins/` is the install cache
managed by `/plugin install`; hand-placed files there are not supported.

---

## 0. Prerequisite — already closed

Revision 2 made backup relocation a blocking prerequisite. **It is done, and it was solved
better than proposed.** Sandbox ADR-0005 ("skill templates are the source of truth") makes
`sandbox_templates/skills/` authoritative and each profile's `claude-home/skills/` a *derived
cache* reconciled on every `up`. Backups are not taken at all — every seeded skill is a copy of
a git-tracked template, so git is the backup. All six stale `*.bak.*` directories are gone.

Nothing to do here at plugin time. The evidence trail is kept because it motivates
[Rule 4](../../docs/distributing-skills-downstream.md) for other consumers: the `.bak` twins
declared the *same* `name:` as their live counterparts and **both loaded**, and
`audit-sandbox.bak` pointed the tier-3 audit skill at a staged `CLAUDE.md` that
`stage-audit-package.sh:61` never puts in the package. A live defect in the sandbox's own
verification path, not a cosmetic duplicate.

### New seeding semantics you can rely on

| Template change | Effect on every profile, next `up` |
|---|---|
| skill added | seeded |
| skill edited | profile copy replaced, with a WARN |
| skill removed | pruned, with a WARN |
| skill locally edited in a profile | replaced from template, with a WARN naming it |

Pruning is **scoped, never a mirror**: only `*.bak.*` and names recorded in
`claude-home/skills/.sandbox-seeded`. An unrecognised directory is reported and left alone —
which matters here, because `claude plugin init` scaffolds into `~/.claude/skills/<name>/` and
a mirroring prune would destroy an agent's own plugin.

## 1. Vendor the plugin — into the existing skills path

```
sandbox_templates/skills/myconv/
```

`ensure_state` (`profile.sh:416-425`) and `reset-skills` (`:1281-1291`) both iterate
`sandbox_templates/skills/*/` and `cp -R` each subdirectory verbatim. They are
**shape-agnostic** — they neither look for nor require a `SKILL.md`. Dropping the plugin here
means seeding and refresh work with **zero changes to `profile.sh`**.

Revision 1 of this document suggested `sandbox_templates/claude/plugins/myconv/`. That was
wrong: it would require new seeding code in a security-sensitive file for no behavioural gain.
Use the skills path — the whole change becomes vendored content plus docs.

Source it from upstream `plugins/myconv/`, which is already the genericised surface. Commit it:
no personal path, no token, no machine-specific value.

## 2. Seed per profile

Nothing to write. `up` converges it into every profile; `reset-skills` is now just "converge
without touching the container". A template edit reaches profiles without anyone remembering a
refresh command.

## 3. Remove the stale unnamespaced twins — two actions

Convergence collapses this. Removing the twins from the template tree now prunes them from
every profile automatically on the next `up`, because they are manifest-recorded.

1. Remove `make-plan/` and `wrap-up/` from `sandbox_templates/skills/`.
2. Point the sync script at `plugins/` so it cannot re-vendor them — **this falls out of step 6
   for free.** Once it sources from upstream `plugins/` instead of `templates/.claude/skills/`,
   it can no longer enumerate the twins.

The per-profile deletion, the resequencing, and the `claude plugin list` gate from revision 2
are all gone. One ordering note survives: confirm `myconv@skills-dir` loads **before** removing
the twins from the template tree, because until it does the loose copies are the only working
ones. That is an ordering note now, not a procedure.

**Upstream is deliberately keeping `templates/.claude/skills/{make-plan,wrap-up}`.** That tree
is the adapt-by-hand surface for *all* consumers, and a repo adopting the conventions may
legitimately want committed skills in its own `.claude/` rather than a plugin. Narrowing the
blueprint to suit one consumer's refresh script would be the wrong trade; the script changes
instead.

**Keep** the sandbox's own `audit-sandbox/` and `web-read/` — sandbox-native, unrelated. Their
`*.bak.*` directories are handled by step 0 (relocated, not kept).

## 4. Settings: nothing to change

Worth stating plainly, because the instinct is to add configuration. A personal-scope
skills-directory plugin needs **none** of:

| Not needed | Why |
|---|---|
| `enabledPlugins` in `settings.json` | skills-dir plugins load by discovery, not enablement |
| `extraKnownMarketplaces` | there is no marketplace in this path |
| `CLAUDE_CODE_PLUGIN_SEED_DIR` | that is for read-only image-baked seeds; see "Rejected" |
| `CLAUDE_CODE_PLUGIN_CACHE_DIR` | nothing is installed into a cache |
| any egress-allowlist change | no host is contacted |

The only setting-shaped action is opting a profile out:
`claude plugin disable myconv@skills-dir`.

**Default it on for every profile.** ~8 tokens always-on is not worth per-profile gating, and
the disable command is the escape hatch.

## 5. Verify

In a **fresh session** — the plugin loads on next session start, not the current one:

```
claude plugin list          # expect: myconv@skills-dir, version 0.1.0, ✔ loaded
/myconv:apply-conventions   # expect: available, from any repo in the workspace
```

Confirm from a *second* repo under the same workspace — that is the property being bought and
the one most likely to be silently wrong. Also confirm **no** second `myconv@skills-dir` entry
reporting "Not loaded — same plugin name", which is step 0 regressing.

If a `SKILL.md` edit doesn't take effect, `/reload-plugins`. (Unverified by the sandbox agent;
`plugin list` and `plugin details` were.)

## 6. Amend the existing sync script — don't add a second one

`scripts/sync-skills-from-conventions.sh` already is the script revision 1 sketched, including
the gitignored pointer (`$CONVENTIONS_DIR` / `.conventions-dir.local`, already at the repo root)
and the on-demand-only rule. It needs two edits:

- **source subpath** → upstream `plugins/`, not `templates/.claude/skills/`;
- **validation gate** → check for `.claude-plugin/plugin.json`. Line 146 gates on a top-level
  `SKILL.md`, and `myconv/` has none — run it unamended and you get
  `skipping 'myconv': no SKILL.md` and a silent no-op that reads as success.
- **make the `variants/` strip recursive** — `rm -rf "$stage/$name/variants"` assumes the
  loose-skill depth. In plugin mode the directory would sit at
  `plugins/myconv/skills/<skill>/variants/`, one level deeper, so the strip silently becomes a
  no-op. There are zero `variants/` directories upstream today, so nothing leaks now; the guard
  just stops guarding, and lapses the day someone adds one. Use
  `find "$stage/$name" -name variants -type d` while you are in the file.

Also: `UPSTREAM.md` is generated and asserts "skills NOT listed here are sandbox-native." That
sentence is false once a vendored plugin lands unless `myconv` gains a row.

## 7. Freshness gate — extend `vendor-check`, and prefer content diff

Put drift detection where builds already fail on drift rather than in a second script.

One refinement on the proposal to echo vendored-vs-upstream `plugin.json` version: **use a
content diff for `myconv` too, not just the version.** The argument made for `myclickup` — that
a rebuilt 0.1.0 with different bytes is the real drift case — applies identically here, and
more so, because `just sync-plugin` upstream regenerates the payload without necessarily
bumping `version`. A version echo is a useful headline; the diff is the gate. *(Accepted
sandbox-side, with the refinement that a missing upstream checkout should skip with a warning
rather than fail, so `vendor-check` stays runnable on a host holding only one checkout.)*

This is now the **only** remaining drift axis. Convergence closed template-tree → profile;
repo → template-tree is still an on-demand human-triggered sync, which is exactly what
`vendor-check` has to watch.

---

## Constraints to respect

- **Never bake into the image at `/root/.claude`** — shadowed by the per-instance bind mount,
  so an image-baked copy is invisible at runtime.
- **Never place it under `/opt`, `/usr`, `/tmp`, `/root/.local`, `/root/.npm-global`.** The
  first two are container-layer and destroyed on recreate; the rest are `noexec` tmpfs.
- **No marketplace install inside a profile.** Seeding is the supported closed-egress path.
- **Remote git is denied to the agent.** If a step needs a push or clone, surface it as a human
  step with the exact command.
- **A refused copy or unreachable host is the boundary working.** Report path or host and stop.

## Rejected alternatives (so they are not re-proposed)

- **`CLAUDE_CODE_PLUGIN_SEED_DIR`** — wants a seed built by `claude plugin install` at image
  build, read from somewhere like `/opt/claude-seed`. `/opt` dies on recreate, the build needs
  network, and every update becomes an image rebuild. Reconsider only for a genuinely
  admin-managed, user-immutable toolkit.
- **Symlinking profiles at the conventions checkout** — breaks on Windows/WSL2, doesn't resolve
  inside a container, couples build cadence to refresh cadence.
- **Keeping loose unnamespaced skills** — no version field, no single unit to refresh, no
  staleness signal. The arrangement that produced the 6- and 34-line drift.
- **Converting `myclickup` into a plugin** — its skill documents a tool version and is
  deliberately coupled to the wheel; a content diff against `src/` is a stronger gate than a
  version field. A plugin wrapper would loosen a coupling that was paid for.

## Sequencing alongside `myclickup`

- **Separate commits, one profile pass.** `myclickup` touches Dockerfile, `claude-settings.json`
  and `allowed_domains.txt` — three security-sensitive files needing a security-impact message,
  verify, and audit. `myconv` touches none. Land them separately, then do **one** `up` pass
  across the three profiles. The revision-2 caveat about that pass firing the `.bak` shadowing
  no longer applies — ADR-0005 removed the backups.
- **`myclickup`'s own §9 needs a correction too:** "skill seeding is first-run-only" is no
  longer true under convergence.
- The two payloads coexist in the same directory without collision:
  `sandbox_templates/skills/myclickup/SKILL.md` (loose → `/myclickup`) and
  `sandbox_templates/skills/myconv/` (plugin → `/myconv:wrap-up`). The shape-agnostic loop
  carrying both unchanged is the strongest confirmation that the skills path is right.
- `UPSTREAM.md` gains a third provenance class: sandbox-native, vendored-from-conventions,
  vendored-from-myclickup — two upstreams with different refresh commands.
- `sandbox_templates/wheels/` is not a skills dir. No seeding interaction.

## Forward note — the landing-zone problem

With `myclickup` you accepted the principle that a tool's skill ships from the tool's own repo.
If that generalises, `sandbox_templates/skills/` becomes a landing zone for N upstreams and
`sync-skills-from-conventions.sh` — named for one of them — is the wrong shape. Not urgent at
two. Revisit at three: a per-upstream pointer table plus one generic sync verb.
