# ADR-0003: Plans live in work/, execution tracking lives in beads

- Status: Accepted
- Date: 2026-07-30
- Deciders: nranthony + agent

## Context

Three forces meet on the question "where does a plan produced for/by an agent live?":

- The reference scaffold's opt-in `work/NNNN-slug/` tier (spec → plan → notes) carries
  an **exit rule** — delete or archive on merge — precisely because a stale plan left in
  the tree poisons future agent context.
- The [Beads adoption plan](../BEADS_ADOPTION_PLAN.md) retires markdown plan/TODO files
  ("Do NOT use markdown TODO lists or plans/ directories for task tracking") in favor of
  bd issues as the execution ledger.
- Claude Code's native plan mode now persists its plans to disk (`~/.claude/plans/` by
  default, redirectable via `plansDirectory`), with random filenames and no lifecycle.

External advice collected in
[docs/PLANNING_TOOLKIT_PLAN.md](../PLANNING_TOOLKIT_PLAN.md) recommended a fourth home —
a permanent `docs/plans/<slug>.md` plus a `docs/status.md` working-memory file. Shipping
the `/make-plan` command forced one canonical answer.

## Decision

**Design-layer plans live in `work/NNNN-slug/plan.md`** (with `spec.md` beside it when
the "what/why" needed pinning), under the existing exit rule: the folder is deleted or
moved to `work/archive/` when the work merges.

**Execution tracking lives in beads where a repo has adopted it** (`.beads/` present):
the plan's task breakdown is filed as a bd epic with dependent tasks, and `plan.md`
links the epic ID instead of keeping a parallel markdown checklist. In repos without
beads, the task breakdown is a section of `plan.md` — a complete workflow, not a
degraded one. Planning tooling never installs or advocates beads; adoption is a
per-repo decision made elsewhere.

The beads "retire plans/ directories" rule is hereby scoped: it applies to **task
checklists**, not design docs. This was implicit in the adoption plan's coexistence
table (specs/design docs are "Keep — WHAT"); this ADR states it canonically.

Native plan-mode files are **drafts, not the durable artifact**. A plan becomes durable
by landing in `work/` (typically via `/make-plan`). Whether to redirect `plansDirectory`
into the repo remains open — see the toolkit plan §5c.

## Consequences

- The `/make-plan` command ships (`.claude/commands/make-plan.md` + the genericised
  mirror in `templates/.claude/commands/`, per the ADR-0002 pattern) encoding this
  decision.
- No repo following these conventions grows a `docs/plans/` or `docs/status.md`.
- Plans inherit `work/`'s lifecycle guarantees — the stale-plan trap is structurally
  closed rather than policed.
- Repos that never opted into `work/` must name their own planning location; the
  command asks rather than inventing a new top-level directory.

## Alternatives considered

- **`docs/plans/<slug>.md` (the external advice):** rejected — permanent location with
  no exit rule; accumulates exactly the stale context `work/` was designed to expire.
- **`docs/status.md` as working memory:** rejected — duplicates beads' role
  (`bd prime` / `bd ready`) and is the file class the adoption plan retires.
- **Beads as the only home (plan lives in an epic description):** rejected — bd issues
  are execution-granular; design rationale, alternatives, and validation plans need a
  reviewable document.
- **Native `plansDirectory` as the home:** rejected as the durable home — random names,
  no lifecycle, no review trail; fine as a drafting surface.
