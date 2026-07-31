# RFC: Example skills for scaffold adopters

- Status: Draft
- Author: nranthony + agent

**Recorded:** 2026-07-21
**Question that prompted it:** what skills should repos adopting the reference scaffold have?
**Concrete next action:** decide whether to ship `write-an-adr` and `bootstrap-nested-package`
as worked examples under `templates/.claude/skills/`, and note them in the reference.
If adopted, this likely warrants an ADR (shipping example skills is a direction, like ADR-0002
was for slash commands). *(Paths updated 2026-07-31 per ADR-0004: the skills slot is
`.claude/skills/` — Claude Code does not read `.agents/skills/` — and the separate
commands slot is gone.)*

---

## The core insight

The best skills for a scaffold-adopting repo aren't domain skills (those vary per repo); they're
the ones that **maintain the provenance chain itself**. That paper trail is the scaffold's whole
value, and it's the thing agents most reliably forget mid-task. A skill auto-fires at the moment
the trail needs updating — when a human would otherwise have to remember to nudge.

## The selection test

A procedure earns a **skill** only if the agent should reach for it *on its own*, it *recurs*, and
it's *self-contained* with a trigger sharp enough to match reliably. If a human should decide when
to run it → still a skill (ADR-0004), but write the `description` to say *when it applies*, or set
`disable-model-invocation: true` if it must never auto-fire. If it's a one-line always-on rule →
**`AGENTS.md`**, not a skill.

## Tier 1 — scaffold-native skills (the strong ones)

Portable to any repo adopting the scaffold, because they exist *because* of the provenance chain.

**`write-an-adr`** — highest value. The agent recognizes it's making a direction-setting decision
that needs a durable home; most don't, unless prompted. Supplies the template, numbering
convention, and append-only/supersede rule.
```yaml
name: write-an-adr
description: Record an architecture decision as a numbered ADR. Use when a
  choice sets a new direction, rejects a prior approach, or supersedes an
  existing decision — anything future work should be able to trace back to.
```

**`bootstrap-nested-package`** — fires when adding a new package/dir with its own `AGENTS.md`;
writes the two-line `CLAUDE.md` stub *in the same commit*, closing the footgun ADR-0001 was written
about (a missing or flattened stub). Silent failure mode → strong skill candidate.
```yaml
name: bootstrap-nested-package
description: Wire up a new package/directory as an agent entry point. Use when
  creating a nested AGENTS.md — generates the sibling two-line CLAUDE.md stub
  and adds the "nearest file wins" pointer.
```

**`start-work-item`** — for repos that opted into `work/`. Fires when non-trivial multi-step work
begins; scaffolds `NNNN-slug/` with spec → plan → notes.

**`close-work-item`** — the exit-rule enforcer. Fires when a PR merges / work is done; deletes or
archives the `work/` folder so a stale `spec.md` doesn't poison future context. The *automatic*
complement to the deliberate `/wrap-up` skill (narrow trigger → safe to auto-fire).

**`promote-rfc-to-adr`** — for repos with `docs/rfcs/`. Fires when an RFC reaches a decision: writes
the ADR, flips the RFC status to `Accepted → ADR-NNNN`.

## Tier 2 — domain skills (repo-specific, not scaffold-native)

Named so adopters know the scaffold expects these too, but written per repo, not shipped as
templates:

- **`run-checks`** / **`run-the-app`** — the repo's actual lint+test+build sequence, or how to launch it.
- **`add-a-migration`**, **`cut-a-release`**, **`add-an-endpoint`** — whatever recurring, error-prone
  procedure this codebase has. Rule: if you've explained it to an agent twice, it's a skill.

## What *not* to auto-trigger

- **`/wrap-up`, release checklist, brownfield adoption** → skills whose `description` states the
  narrow "when" (heavyweight, human usually decides) — add `disable-model-invocation: true` if one
  misfires in practice.
- **"Never commit secrets," "match existing patterns," "ask before adding a dependency"** →
  **`AGENTS.md` golden rules** (always-on, not a procedure to invoke).
- **A `changelog-entry` "skill"** → borderline; better as a step inside `write-an-adr` /
  `close-work-item` or an `AGENTS.md` rule than its own retrieval slot.

## Meta-point for the reference

The scaffold now ships two worked skills (`/wrap-up`, `/make-plan`) but zero *auto-trigger-first*
examples. Tightest move: add `write-an-adr` and `bootstrap-nested-package`
into `templates/.claude/skills/` as worked examples, and note them in the reference — so adopters
copy a working `description:` trigger instead of writing one from scratch (the part people get wrong).
