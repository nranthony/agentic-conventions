# agentic-conventions

A place to get all of my agentic ducks in a row.

The single source of truth for how my repos are set up for agents: the AGENTS.md
blueprint, the reference write-up, and templates to adapt. This repo is a
**reference you hand to an agent** during repo setup — **not** a script that
mutates repos. There is deliberately no scaffolder: a blind copy loop can't know a
repo's context, and the automated version had real footguns (it would flatten a
substantive `CLAUDE.md`, force-enable CI, and set wrong CODEOWNERS). The agent
editing the repo has the judgment; the reference just tells it the desired shape.

## Layout
```
reference/   the blueprint write-up (the "why" and full layout)
templates/   starting-point files to adapt by hand — NOT drop-in
```

- `reference/agentic_native_repo_scaffold.md` — the generic agent-native repo blueprint.
- `templates/` — `AGENTS.md`, `ARCHITECTURE.md`, `CONTRIBUTING.md`, `CODEOWNERS`,
  `.claude/settings.json`, `.github/pull_request_template.md`. Examples to tailor,
  not files to copy verbatim.

## How an agent should apply these
1. Read `reference/` and `templates/` as the *desired shape*.
2. Cross-check against the actual repo you're in — which you already know in detail.
3. Apply the conventions **by hand**, adapting them; skip or tailor anything that
   doesn't fit (owner, CI, an existing substantive `CLAUDE.md`, etc.).
4. Regenerate the thin `CLAUDE.md` (`@AGENTS.md`) next to each `AGENTS.md` by hand.

### Guardrails
- Never overwrite a substantive `CLAUDE.md`. If one exists and isn't a thin
  `@AGENTS.md` pointer, leave it or merge deliberately.
- Don't add CI or `CODEOWNERS` unless the repo wants them, with the correct owner.
- Work on a clean tree; review `git diff` before committing; never push without approval.
- Match the target repo's existing patterns over the generic template.

## Which pieces to actually use (lean core vs. opt-in)
Not every repo needs the whole blueprint. Default baseline:

- **Core:** `AGENTS.md` + thin `CLAUDE.md` + `ARCHITECTURE.md` + `README.md` +
  `.agents/skills/` + gitignored `AGENTS.local.md`.
- **Keep-ish:** `docs/adr/` (durable "why") and a light `.claude/settings.json`.
- **Opt-in per repo, when the repo actually needs it:** `CODEOWNERS`,
  `CONTRIBUTING.md`, PR template, CI (`.github/workflows/`) — the team-ceremony tier;
  and `docs/rfcs/`, `docs/design/`, `work/` — the heavier provenance tier.

## Tiers (what does NOT belong here)
- **User-global** personal config/skills live in `~/.claude/` (back that up separately).
- **Per-repo** `AGENTS.md`/`CLAUDE.md` live committed in each project.
- This repo holds only the **cross-repo shared** conventions and templates.
