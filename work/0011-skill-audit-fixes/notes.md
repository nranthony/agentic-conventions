# Execution notes — 0011 skill audit fixes

Executed 2026-08-12 in three staged commits, in the order the plan mandates (WP7 first,
because it moves where the canonical skills live).

## What landed

**Stage A — `787a2b5` (WP7 + WP6).** The prune: the shared skills collapse to one home
per role. Deleted `templates/.claude/skills/` and the payload-embedded copies under
`plugins/myconv/skills/apply-conventions/templates/.claude/skills/`; re-plumbed the
justfile so `sync-plugin`/`check-plugin-sync` derive the skill list by glob from
`.claude/skills/*/`; retired `check-skill-mirrors`; added `check-plugin-links`,
`check-versions`, `check-vendored` (skips when unconfigured) and the aggregate
`just check`. Version bumped 0.1.0 → 0.2.0 in both manifests with a CHANGELOG entry,
and apply-conventions' skill-delivery guidance rewritten: skills come from the plugin,
never pasted into a consumer repo.

**Stage B — `83d8b0f` (WP1–WP4 + WP8.2).** Portable ClickUp preflight (`myclickup`
identified as a personal CLI from the owner's repo; outside the sandbox, ask the human
to clone and install the wheel — never "installation is impossible"); `[statuses]` gains
`complete` so clickup-report can resolve the terminal status through the table as its
own rule requires, with completion *read* by ClickUp's `status_type`; the ADR-0008
blocker gate implemented in both skills with a live re-read; `templates/.myclickup.toml`
stops shipping the author's real status names as live defaults; apply-conventions gains
a Mode section parsing `$ARGUMENTS`, the `plansDirectory`/`work/` coupling, and a
`templates/.gitignore` mention; `disable-model-invocation: true` on clickup-report
(WP8.2's in-scope action — it is the one skill that writes to a live tracker).

**Stage C — this commit (WP5 + WP8.4).** Shop-window and manifest hygiene: the
marketplace description and the README install section now name all five skills;
`plugin.json` gains `repository` and drops the undocumented `displayName`; the 0.2.0
CHANGELOG entry folds in those consumer-visible lines. WP8.4 polish: the sandbox notice
in `templates/AGENTS.md` is genericised to `<your-sandbox-tool>`. Version stays 0.2.0 —
it has not shipped, so the whole of 0011 is one unreleased entry.

## Still open

- **WP7 step 9 — human step, not done here.** The deployment copy stays stale until the
  owner re-vendors: `just sync-skills` in windows-ai-sandbox, then
  `profile.sh <p> reset-skills` (or the next `up`). Sandbox-side acceptance: exactly one
  copy of each myconv skill in-container at 0.2.0, no phantom nested `make-plan` /
  `wrap-up`. Do not "fix" this by editing `~/.claude/skills/myconv/` — convergence
  reverts it.
- **WP8.1 — CLI-first rewrite, on hold by decision.** clickup-pull hand-encodes
  mechanisms the `myclickup` dev tree implements natively. Held at CLI 0.2.0 until the
  owner iterates the CLI once more and the sandbox image re-vendors it; then a small
  work item moves mechanism into the tool and leaves policy in the skill.
  **Released and executed 2026-08-12 as `work/0013-cli-first-clickup-skills/` (commit
  `88acb87`)** — the CLI is now 0.3.0 in the image and closes every gap the hold was
  waiting on. Archived 2026-08-13 to `work/archive/0013-cli-first-clickup-skills/` once
  0.3.0 was verified loaded in a container.
- **WP8.2's larger thread and WP8.3** (description sharpening, declaring
  `myconv:make-plan` the planning entry point, broader skill-ecosystem intersection; the
  generic-names question) → tracked in `work/0012-skill-development/`, created alongside
  this stage and committed with it for provenance.
