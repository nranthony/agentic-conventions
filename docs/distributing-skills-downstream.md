# Distributing shared skills to downstream repos

How generic agent tooling that lives here — skills like `/wrap-up` and `/make-plan`
([ADR-0004](adr/0004-skills-replace-slash-commands.md)) — reaches the repos and runtimes
that consume it. This is the companion to the README's
[Tiers](../README.md#tiers-what-does-not-belong-here) section: the tiers say *where a
piece belongs*; this doc says *how a shared piece gets there.*

It is guidance for consumers, not a change to this repo. Consistent with
[ADR-0001](adr/0001-reference-not-automation.md), nothing here mutates a downstream repo
on its own — a human or an agent applies it by hand.

## The problem

A skill like `/wrap-up` is **generic** — identical in every repo that wants it. Only
its *source path here* is specific to one machine. When a consumer wants it everywhere,
the naive move is a symlink from the consumer back to this repo. That conflates the
generic content with a personal path, and — as the runtime case below shows — breaks in
exactly the environments agents run in. The content should travel; the path should not.

## Three distribution modes

Pick by *what varies* and *who else consumes it*.

| Mode | Mechanism | Best when | Cost |
|------|-----------|-----------|------|
| **User-scope** | Copy into `~/.claude/skills/<name>/` | You personally want it in every repo you open, one machine, no collaborators | Not versioned, not shared; drifts silently |
| **Plugin + marketplace** | Package the `.claude/` slot as a Claude Code plugin; `/plugin install` from a marketplace (a git repo) | Distributing a versioned toolkit to many repos and/or collaborators | Setup overhead; skills become namespaced (`/myconv:wrap-up`) |
| **Per-repo vendored copy** | Copy the generic `skills/<name>/` folder into the target repo's own `.claude/skills/`, adapt if needed | The skill should be committed with the repo, adapted per repo, or seeded into a runtime | Vendored copies drift from upstream until re-synced |

The first two are covered well by Claude Code natively — and mode 2 is now **adopted**: this
repo is its own marketplace, shipping the `myconv` plugin
([ADR-0007](adr/0007-plugin-distribution.md)). The rest of this doc is about the third —
specifically the **runtime / container** variant, which has sharp edges the naive symlink
hits, and which ADR-0007 resolves by seeding the *plugin* rather than loose skills.

## The runtime / container case

Some consumers aren't a checkout you edit — they're a **runtime that rebuilds often and
seeds a fresh `~/.claude` per instance** (a container sandbox, an ephemeral dev box, a CI
image). There, the symlink instinct fails on three counts, so the rule is **vendor the
content, gitignore only the pointer.**

### Rule 1 — Vendor the generic content (committed)

Keep a committed copy of the generic `skills/<name>/` folder inside the consumer's own
template tree (alongside whatever it already vendors — hooks, settings, dotfiles). It
carries **no personal path**, so builds stay offline, deterministic, and independent of
whether this repo is checked out anywhere. This is also exactly how this repo is designed
to be consumed: vendor a generic template copy and adapt it, never depend on a live link.

### Rule 2 — Seed per instance, don't bake into the image

If the runtime bind-mounts `~/.claude` per instance, anything baked into the image at
`/root/.claude` is **shadowed by that mount**. Skills must be copied into the
per-instance home that *becomes* `~/.claude`, at instance-init time — not `COPY`d into the
image. (Hooks and binaries that live outside `~/.claude` still belong in the image.)

### Rule 3 — Gitignore only the source pointer

The one machine-specific fact is *where this repo lives*. Keep it out of git as a **single
pointer** — an env var (`CONVENTIONS_DIR=…`) or a `.local`-suffixed file — read by a
refresh script. Never a symlink: a symlink's very existence encodes the personal path into
the tree, which is the leak a repo-scan is trying to remove.

### Rule 4 — Don't back up a derived cache; reconcile it, and warn

**If the consumer's copy is reproducible from a tracked source, treat it as a derived cache and
converge it on every start — don't snapshot it.** Git is already the backup. A refresh that
snapshots what it replaces is solving a problem the tracked source has solved, and it creates a
worse one.

The failure it creates: a backup written **inside** the scanned skills directory —
`<name>.bak.<stamp>/` beside `<name>/` — is still discovered, and both copies load.

- **A vendored plugin collides.** Two directories declaring the same `name` in
  `.claude-plugin/plugin.json` are the same plugin; one wins, the other reports *"Not loaded —
  same plugin name"*. Observed: the **backup** wins. The refresh silently reactivates the copy
  it was meant to replace, and still prints success.
- **A loose skill doesn't collide, but still loads.** Skills are listed by directory name, so
  the stale copy appears as a second entry, spends description tokens every session, and stays
  reachable by description-match auto-invocation — serving instructions that were replaced
  precisely because they were wrong.

Both verified in a sandbox profile on 2026-08-10, where the stale twin was directing an audit
skill at a file the audit package does not contain.

The deeper point is that snapshotting is a symptom of **create-only seeding** — a consumer that
only copies when a file is *missing* can never deliver an edit, so someone has to remember a
refresh command, and drift is the default. Converging instead removes that axis. Two guardrails
make convergence safe: **warn before overwriting** a locally-diverged copy, naming it and the
source of truth; and **scope the prune** to a recorded manifest rather than mirroring the
source — `claude plugin init` scaffolds into the same directory, so "delete anything not in the
template" destroys an agent's own work. Report unrecognised directories; leave them alone.

*Fallback:* where a copy genuinely isn't reproducible and must be kept, put it in a sibling tree
(`backups/skills/<name>.<stamp>/`), never inside the scan root.

### Why not a symlink here

- **This class of repo tends to already ban them.** Symlinks break on Windows checkouts,
  IDE-agent checkouts, and zip exports — so tooling that must survive those uses generated
  copies instead.
- **A symlink target outside the build context / mount doesn't resolve inside a
  container.**
- **It couples two cadences that want to be separate:** frequent, reproducible, offline
  *builds* vs. occasional *upstream refresh* that needs this repo present. Vendoring splits
  them cleanly.

The trade you accept: a vendored copy can lag upstream until you re-sync. Given builds must
be reproducible offline, that's the right trade — and a one-command `reset` plus a refresh
script make re-syncing cheap.

## Worked example — a container-sandbox consumer

A container sandbox (e.g. `windows-ai-sandbox`) already seeds per-instance agent config
this way today: an `ensure_state` step copies its vendored `…/skills/*` and
`claude-settings.json` into each profile's `claude-home/` (which is bind-mounted to the
container's `~/.claude`), with `reset-skills` / `reset-settings` to force-refresh. Shared
skills from this repo ride that **existing** mechanism — one reason ADR-0004 consolidated
on skills is that no parallel `commands/` seeding channel needs building:

1. **Vendor** the generic skill into the sandbox's template tree, e.g.
   `sandbox_templates/skills/myconv/` — committed, no personal path. Pull it from this
   repo's generated plugin payload, [`plugins/myconv/`](../plugins/myconv/): that is the
   product tier, and vendoring the whole plugin keeps the skills namespaced as
   `/myconv:*`. (There is no longer a `templates/.claude/skills/` mirror — see work/archive/0011,
   WP7: one home per role.)
2. **Seed per profile** — the existing `ensure_state` skills loop copies it into
   `claude-home/skills/`; `reset-skills` already force-refreshes it. Nothing new to build.
3. **Refresh from upstream** — a small `sync-from-conventions.sh` copies this repo's
   generic skill folders into the sandbox's template tree, reading the source path from a
   gitignored pointer (`CONVENTIONS_DIR` or a `.local` file). It runs when you choose to
   pull upstream — **never** during a container build.

Steps 1–2's seeding mechanism exists today; only the step-3 refresh script is a proposed
addition.

## See also

- [README — Tiers](../README.md#tiers-what-does-not-belong-here) — user-global vs. per-repo
  vs. cross-repo-shared.
- [ADR-0001](adr/0001-reference-not-automation.md) — reference, not automation.
- [ADR-0004](adr/0004-skills-replace-slash-commands.md) — skills as the single procedure
  slot (supersedes the ADR-0002 commands slot this doc previously covered).
