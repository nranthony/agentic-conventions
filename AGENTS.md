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
- Shared procedures → [.claude/skills/](.claude/skills/) (skills like `/wrap-up` and `/make-plan`; invocable by human or model — ADR-0004)
- How consumers pull shared skills downstream → [docs/distributing-skills-downstream.md](docs/distributing-skills-downstream.md)
- The distributable plugin → [plugins/myconv/](plugins/myconv/) + [.claude-plugin/marketplace.json](.claude-plugin/marketplace.json)
  (`/myconv:apply-conventions`, `:make-plan`, `:wrap-up`, `:clickup-pull`, `:clickup-report`
  — ADR-0007). Its `reference/` and
  `templates/` copies are **generated**: edit the root originals, then `just sync-plugin`.
- Proposals & in-flight items → [work/](work/) (NNNN-slug/: proposal → spec → plan → notes;
  distill durable rationale to an ADR, then archive — lifecycle + template in [work/README.md](work/README.md); ADR-0006)
- Why decisions were made → [docs/adr/](docs/adr/) (append-only; template at [docs/adr/0000-template.md](docs/adr/0000-template.md))
- Cross-repo beads registry & rollout plan (prefixes, pinned version, ADOPTION.md) → [conventions/beads/](conventions/beads/)
- ClickUp ↔ `work/` sync (two projections of one item; pull identity in, push status/comments
  back, never plans) → [ADR-0008](docs/adr/0008-clickup-work-sync.md), config in
  [.myclickup.toml](.myclickup.toml), skills `/clickup-pull` + `/clickup-report`.
  **`workspace_id` is intentionally empty** — a workspace for agentic work isn't set up yet,
  so the skills stop rather than run against the token's first workspace.
- What changed **for consumers** → [CHANGELOG.md](CHANGELOG.md) (the plugin's user-visible
  surface only — skills, blueprint, templates. Internal churn stays in ADRs, `work/`, and
  the commit log.)
- Visual one-page map of this repo → [docs/wiki/repo-map.html](docs/wiki/repo-map.html)
- Ephemeral paste-in material → `inbox/` (gitignored; read only when pointed at it, distill into a real doc/ADR, then delete)

There is no ARCHITECTURE.md — the layout above is the whole architecture.

## How to move forward

- Keep the reference and README consistent with each other; they overlap by design
  (README is the summary, reference is the full write-up).
- Direction-setting changes (e.g. re-adding any automation) get an ADR first.
- Templates must stay generic: no real owners, tokens, or repo-specific paths. Nor real
  IDs presented as defaults — an empty pin fails loudly, a wrong one resolves silently.
- **Nothing shipped inside the plugin may link outside its own payload.** An installed
  plugin cannot read the rest of this repo, so a relative link out of
  `plugins/myconv/` (or the `reference/`, `templates/`, and skill files that get copied
  into it) resolves nowhere for every consumer. Cite the ADR by number and bare path
  instead. This has been fixed twice; `rg '\]\(\.\./' plugins/` catches it.
- After touching `reference/`, `templates/`, or the shared skills, run `just sync-plugin` and
  `just validate`. `just check-plugin-sync` and `just check-skill-mirrors` catch the drift.
  If the change alters what a consumer receives, add a CHANGELOG entry and bump `version` in
  `plugins/myconv/.claude-plugin/plugin.json` — an unbumped version means consumers never
  see the change.
- Commit locally with clear messages; never push without approval.
