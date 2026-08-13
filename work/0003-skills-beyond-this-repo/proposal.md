# Proposal: Distributing skills beyond this repo — surfaces outside the checkout

- Status: On hold (2026-08-12)
- Delivered so far: §5 (plugin + marketplace) → ADR-0007; §2 (sandbox refresh) executed in the
  sandbox repo; §1 (user-scope install) documented in `docs/distributing-skills-downstream.md`.
  On hold pending a decision on the claude.ai/Desktop export surface (§3) and the Skills API (§4).
- Author: nranthony + agent
- Migrated from `docs/rfcs/skills-beyond-this-repo.md` ([ADR-0006](../../docs/adr/0006-proposals-are-work-items.md))

## Summary

The shared skills (`/make-plan`, `/wrap-up`) now have one home
([ADR-0004](../../docs/adr/0004-skills-replace-slash-commands.md)) and a consumer guide for
*repo* distribution ([distributing-skills-downstream.md](../../docs/distributing-skills-downstream.md)).
This RFC proposes the directions that reach **outside any repo checkout**: the user-scope
install, the container-sandbox refresh script, claude.ai / Desktop upload (with
per-surface variants and a packaging recipe), the Skills API, and plugin marketplaces.
Each is independently adoptable; none is implemented yet. Verified basis (2026-07-31):
the SKILL.md format is accepted unmodified by Claude Code, claude.ai/Desktop upload, and
the `/v1/skills` API — but each surface holds its **own copy** (no sync), and
`/name` invocation, `$ARGUMENTS`, `argument-hint`, and `disable-model-invocation` are
Claude Code-only; claude.ai fires skills by description match alone.

## Motivation

The skills are useful outside this repo's checkout — in every local repo, inside the
sandbox, and in claude.ai chats where planning happens without a shell. Today each of
those is a manual, undocumented step. The risks of leaving it ad hoc: hand-edited
one-off exports that drift from the canonical copy, and Claude Code-isms (flags,
`work/` paths, `bd` calls) silently failing on surfaces that don't have them.

## Proposal

Ranked by effort/value; 1–2 are near-free, 3 is the substantive piece, 4–5 are deferred.

**1. User-scope install (do anytime, no ceremony).** Copy
`templates/.claude/skills/<name>/` → `~/.claude/skills/<name>/`. Makes the skills
available in every repo opened on that machine. Not versioned; refresh by re-copying.
Cost: drift until re-copied — acceptable at n=1 user.

**2. Sandbox refresh script (completes the runtime story).** The
`sync-from-conventions.sh` step already sketched in the distribution doc: copies
`templates/.claude/skills/*` into the sandbox's vendored template tree, source path from
a gitignored pointer (`CONVENTIONS_DIR` or `.local` file). Runs on demand, never during
builds. Lives in the **sandbox repo**, not here.

**3. claude.ai / Desktop export: packaging recipe + per-surface variants.**

- `justfile` here with `just package-skill <name> [target=claude-ai]` → zips
  `templates/.claude/skills/<name>/` (never the live copy) into gitignored `dist/`,
  folder-at-zip-root as the upload requires. Validates name rules at package time
  (lowercase/hyphens, ≤64 chars, must not contain "anthropic"/"claude").
- Per-surface content overrides live at
  `templates/.claude/skills/<name>/variants/<target>/SKILL.md`; the recipe swaps the
  variant in when a target is named. One source of truth per surface, no hand-editing
  at export time.
  - **If this ships, `just sync-plugin` must exclude `variants/`** ([ADR-0007](../../docs/adr/0007-plugin-distribution.md)).
    It currently copies `templates/` wholesale into the plugin payload, so claude.ai-only skill
    bodies would ride into every consumer and every seeded container. Downstream consumers
    stripping `variants/` at their end are depth-sensitive and will miss the plugin-nested copy —
    the sandbox found exactly that bug in its own sync script. Fix it here, at the source.
  - Two halves of that are already done, 2026-08-13, ahead of this item shipping: the sandbox's
    sync now strips `variants/` recursively, and `just check-vendored` here passes
    `diff -r -x variants` so the vendored copy is not expected to contain what the sync
    deliberately drops. **`just sync-plugin` is still the unfixed half** — it would carry a
    `variants/` directory into the payload. Whoever ships this section fixes that one.
- First variant: **make-plan for claude.ai** — same planning contract (evidence,
  Confirmed/Inferred/Needs-decision, non-goals, validation, approval gate); §1–§2
  rewritten: orient from attached files / Project knowledge instead of the tree, output
  a markdown plan the *human* commits to `work/NNNN-slug/`, task breakdown noted for
  later bd filing, no subagent fan-out, no `$ARGUMENTS`/flags.
- **wrap-up is not ported** — it reconciles a Claude Code session (working tree,
  commits, stubs, compaction); on claude.ai there is nothing to reconcile.
- Upload is always a human step (Settings → Features/Capabilities), separately per
  surface; the recipe just produces the artifact.
- Repo-rules note: a packaging recipe mutates nothing downstream, so it is compatible
  with [ADR-0001](../../docs/adr/0001-reference-not-automation.md)'s spirit — but a `justfile`
  + variants convention is direction-setting, so accepting this RFC section should
  produce an ADR.

**4. Skills API (`/v1/skills`) — defer.** Same zip, uploaded via API and attached to
Messages calls through the code-execution container (no network, no installs there).
No current use case; revisit if a programmatic pipeline wants the planning contract.

**5. Plugin + marketplace — defer.** The versioned, multi-machine/collaborator channel
for Claude Code (marketplace = git repo, `/plugin install`). Verified Claude Code-only —
it does not feed claude.ai, so it replaces modes 1–2 at scale but never mode 3. The
distribution doc already flags it as wanting its own ADR. Trigger to revisit: a second
machine or collaborator consuming these skills.

**Watch item (no action):** the `.agents/skills/` cross-tool standard. Claude Code does
not read it today (ADR-0004); if Cursor/Antigravity/Claude Code converge on it, the
scaffold's skills slot and this RFC's targets both get revisited.

## Open questions

- Which surfaces are actually wanted now? (Guess: 1 and 3; 2 when next touching the
  sandbox repo.)
- Variant maintenance: two SKILL.md bodies per ported skill will drift — is a shared
  core + per-surface preamble worth the extra structure, or is one variant file fine at
  this scale?
- Does the `justfile` belong here, or in the sandbox repo alongside its other tooling,
  with this repo staying pure reference?
- Cadence for refreshing uploaded claude.ai copies after a skill edit (manual is fine;
  is a checklist line in `/wrap-up` warranted?).

## Alternatives

- **One universal SKILL.md that runs everywhere:** rejected — the lowest-common-
  denominator text loses `$ARGUMENTS`/flags in Claude Code and still carries dead
  repo instructions into claude.ai.
- **Hand-edit at export time:** rejected — unversioned drift, exactly what the
  vendor-the-content rule exists to prevent.
- **Symlink/live-link any of it:** rejected already by the distribution doc — content
  travels, paths don't.
