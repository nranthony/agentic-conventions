# {{PROJECT_NAME}}

<!--
  This is a STARTING POINT to adapt by hand, not a drop-in file. Apply the
  conventions to your repo's actual shape; skip or tailor anything that doesn't fit.
  - Replace {{PROJECT_NAME}} with the real name (no scaffolder does it for you).
  - The sibling CLAUDE.md must be a two-line "@AGENTS.md" stub, written by hand.
    NEVER overwrite a repo's existing substantive CLAUDE.md with that stub.
  - Delete the sections below you don't use (ADR/RFC/CHANGELOG/work/ are opt-in).

  Optional: tooling (e.g. windows-ai-sandbox) may inject a managed notice block
  here describing shell restrictions. Leave a BEGIN/END marker pair if you use it;
  do not hand-edit managed blocks.
-->

A project following the agent-native repository blueprint. See the conventions:
https://github.com/nranthony/agentic-conventions

## Start here
When you begin work, in this order:
1. Read this file and ARCHITECTURE.md for the system shape.
2. Check docs/adr/ for decisions that constrain the area you're touching.
3. Check work/ for anything already in flight on this.
4. Match existing patterns in the file you're editing over generic conventions.

## Where things live
- System map & boundaries → [ARCHITECTURE.md](ARCHITECTURE.md)
- Why decisions were made → [docs/adr/](docs/adr/)
- Proposals under discussion → [docs/rfcs/](docs/rfcs/)
- How-to procedures → [.agents/skills/](.agents/skills/) and [docs/runbooks/](docs/runbooks/)
- What changed → [CHANGELOG.md](CHANGELOG.md)
- Per-package specifics → that package's own AGENTS.md (nearest file wins)

## How to move forward (the loop)
- Trivial change (typo, local fix): just do it, then update CHANGELOG if user-visible.
- Non-trivial change: confirm it doesn't contradict an ADR; if it sets a new
  direction, write a short ADR (or an RFC first if it needs discussion).
- After implementing: run the project's checks, reference the ADR/RFC in your
  commit message, and update CHANGELOG. If you used a work/ folder, delete it or
  move it to work/archive/ so stale specs don't pollute future context.
- If you learned something durable (a gotcha, a convention), write it back —
  a new ADR, a skill, or a line here — so the next session doesn't re-derive it.

## Golden rules
- Never commit secrets; never hand-edit generated files (list them).
- Ask before adding a dependency or a new top-level package.

## High-risk paths
List paths that require a written rationale, the verification step, and a
CODEOWNERS review before changing. See enforcement in .claude/settings.json
and .github/workflows/.

@AGENTS.local.md
