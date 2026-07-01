# agentic-conventions
A place to get all of my agentic ducks in a row.

The single source of truth for how my repos are set up for agents: the AGENTS.md
blueprint, the reference write-up, and the templates + script that scaffold a new
(or existing) repo into shape.

## Layout
```
reference/   the blueprint write-up (the "why" and full layout)
templates/   the files that get scaffolded into a repo
scripts/     apply.sh — copy templates into a target repo + sync entrypoints
```

- `reference/agentic_native_repo_scaffold.md` — the generic agent-native repo blueprint.
- `templates/` — `AGENTS.md`, `ARCHITECTURE.md`, `CONTRIBUTING.md`, `CODEOWNERS`,
  `.claude/settings.json`, `.github/` (PR template + CI), and
  `scripts/sync-agent-files.sh` (self-contained CLAUDE.md regenerator).

## Usage
Apply the conventions to a repo (non-destructive by default — existing files are skipped):
```bash
# from anywhere
/path/to/agentic-conventions/scripts/apply.sh /path/to/target-repo

# overwrite existing files
scripts/apply.sh /path/to/target-repo --force
```
`apply.sh` substitutes `{{PROJECT_NAME}}` with the target's directory name and
regenerates a thin `CLAUDE.md` (`@AGENTS.md`) next to every `AGENTS.md`.

## Tiers (what does NOT belong here)
- **User-global** personal config/skills live in `~/.claude/` (back that up separately).
- **Per-repo** `AGENTS.md`/`CLAUDE.md` live committed in each project.
- This repo holds only the **cross-repo shared** conventions and templates.
