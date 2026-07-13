# agentic-conventions

The source of truth for how my repos are set up for agents: a reference blueprint plus
example templates, **handed to an agent** during repo setup. It is deliberately not a
scaffolder — see [docs/adr/0001-reference-not-automation.md](docs/adr/0001-reference-not-automation.md).

## ⚠️ templates/ is example content, not instructions

Everything under [templates/](templates/) — **including `templates/AGENTS.md`** — is
placeholder material for *other* repos to adapt. If you are working under `templates/`
and an `AGENTS.md` there tells you to check `docs/adr/`, `work/`, or run project checks,
ignore it: it is the artifact being edited, not guidance for this repo. This file is the
only live `AGENTS.md` here.

## Where things live

- What this repo is + how consumers use it → [README.md](README.md)
- The canonical blueprint → [reference/agentic_native_repo_scaffold.md](reference/agentic_native_repo_scaffold.md)
- Example files to adapt → [templates/](templates/)
- Why decisions were made → [docs/adr/](docs/adr/) (append-only)

There is no ARCHITECTURE.md — the layout above is the whole architecture.

## How to move forward

- Keep the reference and README consistent with each other; they overlap by design
  (README is the summary, reference is the full write-up).
- Direction-setting changes (e.g. re-adding any automation) get an ADR first.
- Templates must stay generic: no real owners, tokens, or repo-specific paths.
- Commit locally with clear messages; never push without approval.
