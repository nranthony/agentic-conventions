# Handoff: prune the myconv skill copies — with the sandbox seeding pipeline as a hard constraint

**To:** the agent working in `agentic-conventions`
**From:** the host-side agent in `windows-ai-sandbox` (owner of the deployment tier)
**Date:** 2026-08-12

## Decision

Adopt option (b) — collapse six homes to three, one per role:

| Role | Home | Owner |
|---|---|---|
| Canonical | `agentic-conventions/.claude/skills/` | you |
| Product | `agentic-conventions/plugins/myconv/` | you (synced from canonical) |
| Deployment | container `~/.claude/skills/myconv/` | **windows-ai-sandbox — not you** |

Delete tier (1) `templates/.claude/skills/` and tier (4) the skill copies embedded
inside the payload at `plugins/myconv/skills/apply-conventions/templates/.claude/skills/`.
Rewrite `apply-conventions` to say skills come from the installed/seeded plugin and
are never pasted into a consumer repo.

## How tier (5) actually works — read before touching anything under `~/.claude/skills/`

Your audit correctly flagged the `.sandbox-seeded` marker. Here is the full pipeline
it marks. The deployment copy is the **end of a vendoring chain owned by
windows-ai-sandbox**, with a convergence step that runs on every container `up`:

```
agentic-conventions: plugins/myconv/                        (your product tier)
        │  scripts/sync-skills-from-conventions.sh          (manual dev action,
        │  a.k.a. `just sync-skills` in windows-ai-sandbox;  never runs in builds)
        ▼
windows-ai-sandbox: sandbox_templates/skills/myconv/        (vendored copy; the rev
        │                                                    it was cut from is
        │                                                    pinned in UPSTREAM.md —
        │                                                    currently 3f60422)
        │  converge_skills() — runs on EVERY `profile.sh <p> up`
        │  and on `profile.sh <p> reset-skills`  (ADR-0005)
        ▼
host: ~/.ai-sandbox/profiles/<p>/claude-home/skills/myconv/ (derived cache)
        │  bind mount
        ▼
container: ~/.claude/skills/myconv/                          → loads as myconv@skills-dir
```

Consequences you must respect:

1. **Never edit `~/.claude/skills/myconv/` directly.** ADR-0005 makes the sandbox
   template the source of truth and the profile copy a derived cache: on the next
   `up`, `converge_skills` **overwrites** any divergent copy (with a warning, no
   backup) and **prunes** any skill no longer in the template. A hand re-seed is
   guaranteed to be reverted — this is exactly the "next container recreate will
   resurrect the stale copy" failure you predicted, and it is by design.
2. **The only valid re-seed route** is: land your changes upstream → the user runs
   `just sync-skills` in windows-ai-sandbox → `scripts/profile.sh <profile>
   reset-skills` (or just the next `up`). Those steps are the user's / host agent's
   to run; your job ends at the upstream commit.
3. **"Stale" is between the repos, not inside the sandbox.** Verified today: the
   seeded profile copy is byte-identical to the sandbox template. The staleness you
   saw is upstream-head vs vendored rev `3f60422`. The sandbox chain is working as
   designed; the missing step is a re-vendor after your recent upstream changes.
4. **Tier (4) is already deployed everywhere.** The vendored template — and therefore
   the seeded copy in every profile — currently contains
   `myconv/skills/apply-conventions/templates/.claude/skills/{make-plan,wrap-up}/SKILL.md`.
   So the catalogue-photo contamination isn't limited to consumer repos that paste;
   it rides the seed into every repo on every profile. Deleting tier (4) upstream
   automatically removes it from the seed on the next sync — one more reason (b) is
   the right cut.

## Your work items (all inside agentic-conventions)

1. Delete `templates/.claude/skills/` (tier 1); repoint your justfile sync to use
   `.claude/skills/` as canonical → `plugins/myconv/skills/` as payload.
2. Delete the embedded copies under
   `plugins/myconv/skills/apply-conventions/templates/.claude/skills/` (tier 4).
3. Rewrite `apply-conventions` so it never pastes skills into a consumer repo:
   the plugin (installed or sandbox-seeded) is the delivery mechanism. This retires
   tier (6) as a concept.
4. **Bump `plugins/myconv/.claude-plugin/plugin.json` `version`** (0.1.0 → 0.2.0),
   and adopt the discipline: any payload change bumps it. The sandbox's UPSTREAM.md
   pins the synced rev, but the version field is what's visible in-container.
5. Keep the path `plugins/myconv/` and the `.claude-plugin/plugin.json` marker
   stable — the sandbox sync script keys plugin discovery on exactly that shape.
   Renaming or restructuring it breaks the vendoring silently.
6. Your proposed `just check-seeded` should diff `plugins/myconv/` against the
   sandbox's `sandbox_templates/skills/myconv/` (path via `.conventions-dir.local`-style
   pointer or env), **not** against `~/.claude/skills/myconv/` — the latter is a
   derived cache two steps removed and can be legitimately mid-convergence.

## Cross-repo note (handled on the sandbox side, but so you know)

The sandbox sync script also has a loose-skill surface pointing at your
`templates/.claude/skills/` — the tier you are deleting. Nothing currently vendors
through it (only the `myconv` plugin is in UPSTREAM.md), so the deletion is safe,
but the sandbox side will update that path to the new canonical surface. Don't
keep tier (1) alive on the sandbox's account.

## Acceptance (sandbox side will verify after re-vendor)

- `just sync-skills` in windows-ai-sandbox picks up the new payload; UPSTREAM.md
  rev advances; `bash scripts/profile-skills.test.sh` still 19/19.
- After `reset-skills`: in-container skill list shows exactly one copy of each
  myconv skill (`/myconv:*`), version 0.2.0, and no nested phantom
  `make-plan`/`wrap-up` from the templates folder.
