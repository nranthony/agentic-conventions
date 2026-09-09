# Skill feedback: make-plan — step 4 assumes `docs/adr/` exists; repos with a different decision log have nowhere sanctioned to put a draft ADR

- From: ikigai (2026-09-08)
- Version: `myconv 0.7.0 skill:288a2f0cf19a` (VERSION sidecar beside `make-plan/SKILL.md`)
- Install mode: vendored container copy (seeded at `~/.claude/skills/myconv/`, all files dated 2026-08-26 with a `.claude-plugin/plugin.json` naming `nranthony/agentic-conventions` 0.7.0)
- Invocation: `/myconv:make-plan review @inbox/bullet-point-types-seed-notes.md and existing context in this repo regarding bullet point types and emphasis and representations. Revisit the different bracket types … in the context of the new blocks schema system`
- Artifact: skill
- Broke at: "## 4. Consequential decisions → draft ADRs" — "draft a `Proposed` ADR in `docs/adr/` (repo's template and numbering)" — in tension with "## 2. Where the plan lives" — "If it has neither, ask where the plan should live — don't invent a new top-level directory."
- Frequency: every run in a repo without `docs/adr/`
- Symptom: assumed-repo-shape
- Verdict: conditional on the repo having `docs/adr/`. This repo has no `docs/`, no `work/`, no `.beads/`; its planning location is `dev_plans/` and its decision log is a markdown table (`dev_plans/decisions_v0_session.md`, rows numbered #1–#17 with D/P/X status). The choice needed an ADR by the skill's own test (it changes a schema contract and a storage convention), so step 4 fired with no valid target.
- Risk class: mechanical
- Workaround applied locally: wrote the plan to `dev_plans/bullet_types_emphasis_plan.md` and the draft ADR to `dev_plans/adr_draft_inline_emphasis_encoding.md` beside it, with a header line saying it becomes rows #18–#20 of the decisions table on acceptance. Did not create `docs/adr/`.

## Proposed edit

Under "## 4. Consequential decisions → draft ADRs", after "draft a `Proposed` ADR in `docs/adr/` (repo's template and numbering)", add:

> If the repo has no `docs/adr/`, do not create one. Use the repo's own decision record if it has one (a decisions table, a `DECISIONS.md`, a numbered log) by drafting the entry in the same format as a *proposed* row or file placed next to the plan, and say in the plan where it lands on acceptance. Only when the repo has no decision record at all do you ask where ADRs should live — the same rule as §2 for the plan itself.

Under "## 2. Where the plan lives", the sentence "If the repo has its own planning location, use that." could add "(and note that the ADR rule in §4 follows the same fallback)" so the two sections read as one rule.
