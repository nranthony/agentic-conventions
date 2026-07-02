# IN_TRANSIT — agentic-conventions

**Status:** pivot executed (2026-07-02). The repo is now a *reference handed to agents*,
not a scaffolder — all automated/damaging scripts removed, README + reference doc rewritten
to match. Remaining items are optional polish (see the now-checked task list). The
"Guardrails while applying conventions to OTHER repos" section below still stands.

Last updated: 2026-07-02.

---

## Where things stand now

The repo (`github.com/nranthony/agentic-conventions`, branch `main`) currently holds:

```
README.md
reference/agentic_native_repo_scaffold.md    the blueprint write-up (KEEP — this is the point)
templates/                                    AGENTS.md, ARCHITECTURE.md, CONTRIBUTING.md,
                                              CODEOWNERS, .claude/settings.json,
                                              .github/{pull_request_template.md,workflows/ci.yml},
                                              scripts/sync-agent-files.sh
scripts/apply.sh                              automated scaffolder  (SLATED FOR REMOVAL — see below)
```

It began life as an **automated scaffolder**: `apply.sh` copied templates into a target
repo and regenerated `CLAUDE.md` files. We are moving away from that model.

---

## Direction: reference, not automation

Going forward this repo is a **reference to hand to agents during repo setup**, not a
script that mutates repos. The setup flow should be:

1. A human (or a supervising agent) points the working agent at this repo's `reference/`
   and `templates/` as the *desired shape*.
2. The agent **cross-checks against the actual repo it's in** — which it already knows in
   detail — and applies the conventions **by hand**, adapting them rather than copying blindly.
3. The agent skips or tailors anything that doesn't fit (owner, CI, existing CLAUDE.md, etc.).

Rationale: a blind scaffolder can't know a repo's context; the agent editing the repo does.
Judgment beats a copy loop.

---

## Why we're dropping the automation — the dangers

`apply.sh` (and the shipped CI) have real footguns. These are the reasons for removal, and
the things a hand-applying agent must watch for:

- **Unconditional CLAUDE.md overwrite.** The sync step rewrites the `CLAUDE.md` next to
  every `AGENTS.md` to a 2-line stub — *not* gated by the skip logic or by `--force`.
  Any hand-written, substantive `CLAUDE.md` gets flattened. Repos with rich CLAUDE.md files
  today (`sandbox/windows-ai-sandbox` ~257 lines, `sandbox/macolima` ~103, both
  `temp_audit_package` ~247/257) are safe *only* because they lack a sibling `AGENTS.md`.
  The moment one gains an `AGENTS.md`, the scaffolder would destroy its CLAUDE.md.
- **`--force` wipes customization.** It overwrites every template-managed file
  (AGENTS.md, settings.json, ci.yml, CODEOWNERS) with generic boilerplate.
- **Shipping CI turns on Actions.** Dropping `.github/workflows/ci.yml` into a repo starts
  GitHub Actions on push/PR, and the job *fails* until synced CLAUDE.md files are committed —
  red X's across repos.
- **CODEOWNERS `* @nranthony`** is wrong for `experiencetherapod/*` and `fluidmomenta/*`
  repos and can change PR approval requirements.
- **Unscoped `find`** writes CLAUDE.md into vendored/nested dirs (e.g. `node_modules`).

---

## Tasks for the agent (auto mode OK)

Do these in the `agentic-conventions` repo unless noted. Commit locally with clear messages;
do **not** push unless asked.

- [x] **Remove `scripts/apply.sh`.** Done 2026-07-02.
- [x] **Remove `templates/.github/workflows/ci.yml`.** Done; `templates/.github/` still holds
      `pull_request_template.md` (kept).
- [x] **Remove `templates/scripts/sync-agent-files.sh`.** Done — no manual helper kept; the
      reference now says to write the thin `CLAUDE.md` by hand (no auto-run script anywhere).
- [x] **Rewrite `README.md`** as a *reference handed to agents*, not a scaffolder. `apply.sh`
      usage removed; "How an agent should apply these" flow + guardrails added; plus a
      "lean core vs. opt-in" tiering section.
- [x] **Reframe `templates/` as examples** — README now calls them starting points to adapt,
      not drop-in. (Inline per-file caveats inside the template files themselves are still
      optional follow-up if desired.)
- [x] Leave `reference/agentic_native_repo_scaffold.md` as the canonical blueprint — kept, and
      trimmed: removed the embedded sync-script + CI-wiring recommendation (contradicted the
      no-automation decision) and added a "lean core vs. opt-in" tier section.

## Guardrails while applying conventions to OTHER repos (by hand)

- Never overwrite a substantive `CLAUDE.md`. If one exists and isn't a thin `@AGENTS.md`
  pointer, leave it or merge deliberately.
- Don't add CI or CODEOWNERS unless the repo actually wants them, with the correct owner.
- Work on a clean tree; review `git diff` before committing; never push without approval.
- Match the target repo's existing patterns over the generic template.

---

## Out of scope / do not touch
- `ext/` and `evaneil/` folders anywhere in the workspace — leave alone.
- `~/.claude/` (user-global config) — separate concern, not part of this repo.
