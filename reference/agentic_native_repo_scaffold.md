# Agent-Native Repo Scaffold (generic)

A portable starting layout for any repository, on any system or container, that you want agents to operate in well. This intentionally ignores language, build, and runtime specifics (those belong in per-package files) and focuses on the **administrative layer**: instructions, provenance, decisions, documentation, and the bookkeeping that lets an agent orient itself and know how to move forward.

Two ideas carry the whole thing:

1. **One entry point.** `AGENTS.md` is the source of truth and the *index*. An agent reads it first, and from it learns where everything else lives.
2. **A durable paper trail.** Every "why," "what changed," and "how we do X" has one obvious home that's committed to the repo — not held in an agent's ephemeral session memory.

---

## The layout

```
.
├── AGENTS.md                  # ENTRY POINT: rules + index/map + operating procedure
├── CLAUDE.md                  # generated thin file: "@AGENTS.md"  (Claude Code reads this)
├── ARCHITECTURE.md            # the mental map: lean diagram + boundaries
├── README.md                  # human onboarding (install/run). NOT the agent's file.
├── CHANGELOG.md               # provenance of notable changes over time
├── CONTRIBUTING.md            # how a change gets proposed → reviewed → merged
├── CODEOWNERS                 # which paths require which reviewers (enforcement)
├── AGENTS.local.md            # gitignored personal context, imported by AGENTS.md if present
│
├── .agents/
│   └── skills/                # reusable procedural know-how, auto-discoverable
│       └── <skill-name>/
│           └── SKILL.md       #   folder + SKILL.md with name/description frontmatter
│
├── .claude/
│   ├── settings.json          # committed: permissions + hooks (the enforcement layer)
│   ├── settings.local.json    # gitignored personal overrides
│   ├── commands/*.md          # repeatable workflows exposed as /slash-commands
│   └── rules/*.md             # high-precedence hard rules (use sparingly)
│
├── .github/
│   ├── pull_request_template.md
│   └── workflows/             # CI: lint, test, and the gate checks that enforce the rules
│
├── docs/
│   ├── adr/                   # DECISION PROVENANCE: numbered, append-only records
│   │   ├── 0000-template.md
│   │   └── 0001-record-architecture-decisions.md
│   ├── rfcs/                  # proposals under discussion (precede an ADR)
│   ├── design/                # durable design references
│   └── runbooks/             # operational how-tos that aren't skills
│
└── work/                      # ACTIVE-WORK PROVENANCE (optional): the in-flight trail
    └── NNNN-slug/             #   spec.md → plan.md → notes.md for a feature in progress
```

Per-language / per-package directories (each with its own `AGENTS.md` + generated `CLAUDE.md`) hang off this as needed; they hold the build/test/env specifics and are deliberately out of scope here.

---

## Not everything at once — lean core vs. opt-in

This is the full menu, not a mandatory checklist. Most repos want the lean core and
add the rest only when a concrete need appears. Adopt in this order:

- **Core (every repo):** `AGENTS.md`, the thin `CLAUDE.md`, `ARCHITECTURE.md`,
  `README.md`, `.agents/skills/`, and gitignored `AGENTS.local.md`. This alone makes a
  repo agent-native.
- **Keep-ish (most repos):** `docs/adr/` for the durable "why", and a light
  `.claude/settings.json`.
- **Opt-in — team ceremony (add when others review/merge):** `CODEOWNERS`,
  `CONTRIBUTING.md`, the PR template, CI gate checks. Solo, these are overhead — and
  `CODEOWNERS` with the wrong owner actively changes approval requirements, so don't add
  it reflexively.
- **Opt-in — heavier provenance (add for long-lived or high-autonomy repos):**
  `docs/rfcs/`, `docs/design/`, `work/`. If in-flight work is tracked outside the repo
  (issues, ClickUp, etc.), skip `work/` entirely.

Rule of thumb: start at the core and let real need pull each further piece in. An empty
`docs/rfcs/` no one uses is worse than not having it.

---

## The provenance chain — which file answers which question

This is the core of "how agents know where to look." Each question has exactly one home, so neither an agent nor a human has to guess.

| The question | Lives in | Shape |
|---|---|---|
| What are the rules, and where is everything? | `AGENTS.md` | Short, indexed, links out |
| What does the system look like? | `ARCHITECTURE.md` | One diagram + boundaries |
| **Why** does this exist / why this way? | `docs/adr/` | Numbered, append-only, status-tracked |
| What change is being *proposed*? | `docs/rfcs/` | Discussion before a decision |
| What changed, and when? | `CHANGELOG.md` + commit messages | Reverse-chronological |
| How do I *do* a recurring task? | `.agents/skills/<name>/SKILL.md` | Self-contained, auto-triggered |
| Operational how-to (not a skill) | `docs/runbooks/` | Step-by-step |
| Who must approve changes here? | `CODEOWNERS` | Path → reviewer |
| What's in flight right now? | `work/NNNN-slug/` | spec → plan → notes |
| How does a change get merged? | `CONTRIBUTING.md` | Process |

The lifecycle reads left to right: an **RFC** proposes → an **ADR** records the decision → **work/** tracks the implementation → the **CHANGELOG** and commit (referencing the ADR) record the outcome. That chain is the provenance: any line of code can be traced back to the decision and the reasoning that produced it.

---

## Discoverability: what's actually auto-loaded (and what isn't)

Design around this, because it's the difference between an elegant tree and an inert one.

- **`AGENTS.md` (root and nested)** is auto-loaded. Cursor and Gemini/Antigravity read it natively; Claude Code reads it through the generated `CLAUDE.md` that imports it (`@AGENTS.md`). **Nearest file wins**, so keep the root lean and push specifics down.
- **Skills** (`.agents/skills/<name>/SKILL.md`) are the *one* offload mechanism that auto-discovers and auto-triggers by description. Use them for procedures you want the agent to reach for on its own.
- **Everything under `docs/`, `ARCHITECTURE.md`, `work/`** is **not** auto-loaded. It's only seen if `AGENTS.md` links to it *and* the workflow tells the agent when to read it. That's fine — it keeps context lean — but it means `AGENTS.md` must act as an index, and the links must be **relative** (`[docs/adr/](docs/adr/)`), never absolute `file://` paths, so they stay portable across checkouts, zips, and containers.

So the rule of thumb: **rules and the index** go in `AGENTS.md`; **procedures the agent should auto-invoke** become skills; **everything else** is referenced on demand.

---

## Entrypoint wiring (portable, no symlinks)

Generate thin per-tool entrypoints instead of symlinking — symlinks break on some Windows checkouts, IDE agent sandboxes, and zip exports. `CLAUDE.md` at every level that has an `AGENTS.md` is just:

```markdown
# CLAUDE.md
@AGENTS.md
```

Write these by hand — there are only ever a handful, one per directory that has an
`AGENTS.md`. **Deliberately no sync script.** An automated regenerator that walks the
tree and writes `CLAUDE.md` next to every `AGENTS.md` will happily flatten a
*substantive* hand-written `CLAUDE.md` into the two-line stub — a real footgun. When you
add a new package with its own `AGENTS.md`, add the two-line `CLAUDE.md` beside it in the
same commit. If you ever want a check, prefer a read-only CI assertion that *fails* when a
`CLAUDE.md` is missing or malformed over anything that *writes* files.

(`GEMINI.md` is no longer needed — the standalone Gemini CLI is retired and Antigravity reads `AGENTS.md` natively.)

---

## Advice vs. enforcement

`AGENTS.md` tells a cooperative agent what to do; it does not *stop* anything. For rules that actually matter, back the prose with mechanisms that don't depend on the agent reading them:

- **`.claude/settings.json`** — permission rules that set sensitive paths to `ask`/`deny`, and `PreToolUse` hooks that block edits to protected files. Commit this so it's shared.
- **`CODEOWNERS` + branch protection** — force human review on high-risk paths.
- **CI gate checks** — run the required verification whenever a protected path changes.

State the intent in `AGENTS.md` ("why"); enforce it in hooks/CI ("can't"). Don't conflate "the agent was told" with "the control exists."

---

## Starter templates

### `AGENTS.md` (the centerpiece — index + procedure)

```markdown
# <Project Name>

<One sentence: what this repo is.>

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
  commit message, and update CHANGELOG.
- If you learned something durable (a gotcha, a convention), write it back —
  a new ADR, a skill, or a line here — so the next session doesn't re-derive it.

## Golden rules
- Never commit secrets; never hand-edit generated files (list them).
- Ask before adding a dependency or a new top-level package.
- <Repo-wide invariants the agent must respect.>

## High-risk paths
Changes to <list paths> require: a written rationale in the commit, the
verification step <cmd>, and a CODEOWNERS review. See enforcement in
.claude/settings.json and .github/workflows/.

@AGENTS.local.md
```

### `docs/adr/0000-template.md`

```markdown
# ADR-NNNN: <short decision title>

- Status: Proposed | Accepted | Superseded by ADR-XXXX
- Date: YYYY-MM-DD
- Deciders: <people / agent + reviewer>

## Context
<The forces at play, constraints, what problem prompted this.>

## Decision
<What we decided to do.>

## Consequences
<Trade-offs accepted, what becomes easier/harder, follow-ups.>

## Alternatives considered
<Options rejected and why.>
```

ADRs are **append-only**: never rewrite an accepted one — supersede it with a new record and flip the old one's status. That immutability is what makes the decision history trustworthy.

### `docs/rfcs/TEMPLATE.md`

```markdown
# RFC: <title>

- Status: Draft | In review | Accepted → ADR-NNNN | Rejected
- Author: <name / agent>

## Summary
## Motivation
## Proposal
## Open questions
## Alternatives
```

### `.github/pull_request_template.md`

```markdown
## What & why
<Summary, and the ADR/RFC/issue this traces back to.>

## Checklist
- [ ] Linked the decision record (ADR/RFC) if this changes direction
- [ ] Updated CHANGELOG / docs as needed
- [ ] Ran the project's checks
- [ ] Touches a high-risk path? Rationale included + reviewer requested
```

---

## New-repo setup checklist

1. Add `AGENTS.md` (use the template), `ARCHITECTURE.md`, `README.md`, `CHANGELOG.md`, `CONTRIBUTING.md`, `CODEOWNERS`.
2. Create `docs/adr/` with the template and a first ADR — `0001-record-architecture-decisions.md` — so the practice is self-documenting.
3. Add `.github/pull_request_template.md` and a CI workflow.
4. Add `.claude/settings.json` (permissions + hooks) and the PR template; gitignore `AGENTS.local.md`, `**/AGENTS.local.md`, `.claude/settings.local.json`.
5. Write the thin `CLAUDE.md` (`@AGENTS.md`) next to each `AGENTS.md` by hand — no generator (see "Entrypoint wiring").
6. Keep `AGENTS.md` short. The moment it sprawls, move detail into a skill, an ADR, or a nested `AGENTS.md`.
```