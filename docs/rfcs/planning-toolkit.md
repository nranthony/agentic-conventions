# Planning Toolkit Plan — how plans get requested, produced, and consumed

**Status:** Partially implemented (2026-07-30) — §3/§4 approved and shipped: `/make-plan`
lives at `.claude/commands/make-plan.md` (+ template mirror), and "where plans live" is
decided in [ADR-0003](adr/0003-where-plans-live.md). The §4 draft below is kept for the
rationale; the shipped command is canonical. §5 items a/c/d/e remain open for discussion.
**Recorded:** 2026-07-30
**Question that prompted it:** there is no unified, effective framework for asking an
agent to produce a plan that fits our workflow and repo structures. Incoming material:
[docs/incoming/gpt-5-6-terra_plan_prompt_skill_command_notes.md](incoming/gpt-5-6-terra_plan_prompt_skill_command_notes.md).
**Concrete next action:** settle the remaining §5 discussion items (skill/command
convergence ADR, `plansDirectory` in the settings template, `docs/incoming/` lifecycle,
the `*_PLAN.md`-vs-rfcs question).

---

## 1. The native landscape (verified against Claude Code docs, 2026-07-30)

Facts that changed since the GPT notes were written, and that the toolkit should build on:

- **Plan mode persists plans to disk.** Plans save as markdown to `~/.claude/plans/`
  (random names); `plansDirectory` in settings.json can redirect them into the repo.
  `Ctrl+G` opens the plan in an editor before approval; approval exits into an execution
  mode. The `~/.claude/plans/` default is *not* durable across heavy compaction — the
  documented workaround is keeping plans in the repo.
- **Ultraplan** (`/ultraplan`, or "refine with Ultraplan" from local plan mode) escalates
  a big plan to a long cloud Opus planning run with a browser review UI, then teleports
  the approved plan back for local implementation. The right tool for 30-min-plus,
  high-ambiguity plans.
- **Skills and slash commands have converged.** Both create `/name` invocations. Skills
  (`SKILL.md`) now carry `disable-model-invocation: true` (making a skill human-invoke
  only), supporting files (templates, examples, scripts), `allowed-tools`, `model`, and
  `context: fork`. Official guidance now calls `.claude/commands/*.md` the legacy form
  and recommends skills for new work. **The ADR-0002 fork (auto-invoke → skill,
  human-invoke → command) survives conceptually but is now expressible inside one
  mechanism** — see §5a.
- **Built-in Plan and Explore subagents** exist for research fan-out during planning;
  custom `.claude/agents/*.md` support `permissionMode: plan` for read-only investigators.
- Commands/skills can be made effectively read-only via `allowed-tools` (omit Write/Edit).

## 2. What to keep from the GPT notes — and what conflicts with our scaffold

The notes' *planning contract* is genuinely good and worth adopting nearly verbatim:

- Read the source-of-truth docs first; **repo evidence over assumption**; never claim a
  file/API/convention exists without verifying it.
- Surface conflicts between sources instead of silently resolving them.
- Ask questions only when the answer materially changes scope, architecture, security,
  data, cost, or acceptance criteria.
- Label significant statements **Confirmed / Inferred / Needs-decision**.
- Route consequential choices into a **draft ADR** rather than burying rationale in the plan.
- Explicit **non-goals**, a **validation plan**, **acceptance criteria**, and a final
  **approval gate** ("do not implement; here's what needs sign-off").

Four things conflict with this repo's existing decisions and must be rewired:

| GPT notes say | This repo says | Resolution |
|---|---|---|
| Plans live in `docs/plans/<slug>.md`, indefinitely | `work/NNNN-slug/` (spec → plan → notes) **with an exit rule** — stale plans poison future context (reference scaffold) | Plans land in `work/NNNN-slug/plan.md`; delete/archive on merge |
| Keep a `docs/status.md` working-memory file | Beads is the working-memory layer (`bd prime`, `bd ready`); the adoption plan explicitly retires markdown status/plan files | No `status.md` — that's exactly the file class beads replaces |
| Task breakdown lives in the plan / `tasks.json` | Beads owns execution tracking; plan docs are the design layer ("Keep — WHAT" in the coexistence table) | Pre-beads: breakdown section in `plan.md`. Post-beads: file a bd epic + tasks, link the epic ID from the plan |
| Ship a `planning-docs` **skill** + thin `/plan-feature` command | ADR-0002 fork + the EXAMPLE_SKILLS_PLAN selection test: heavyweight, human-decides-when → command, not auto-trigger | One self-contained human-invoked command; no skill indirection (revisit under §5a) |

Their `/implement-task` companion is good content, but its core job — claim one bounded
task, stay in scope, report evidence — is precisely what beads' claim/close discipline
will own. **Hold it** until the beads pilot decides the execution layer, rather than
building a markdown task protocol we'd retire in weeks.

## 3. Recommended toolset (layered)

1. **Ad-hoc / interactive planning → native plan mode.** Shift+Tab, investigate
   read-only, `Ctrl+G` to edit, approve. No custom tooling needed; don't wrap what the
   harness already does well. Escalate genuinely large plans to **Ultraplan**.
2. **Durable, reviewable plans → `/make-plan` (new command, §4).** Human-invoked when a
   change is big enough that the plan must outlive the session: it runs the planning
   contract and writes `work/NNNN-slug/plan.md` (+ `spec.md` when the "what" needed
   pinning), drafts ADRs for consequential choices, and ends at an approval gate.
   This is the piece we're missing today.
3. **Execution handoff → fresh session per task, beads once adopted.** Today: implement
   from the approved `plan.md` one task at a time, updating the plan's task statuses.
   After beads: `/make-plan` files the breakdown as a bd epic + dependent tasks, and
   the daily rhythm (`bd ready` → claim → close) takes over. No `/implement-task`
   command for now.
4. **Research during planning → Explore/Plan subagents.** The command should say
   "fan out investigation to subagents when the surface is wide" rather than encoding
   its own research protocol.

Non-Claude tools: beads is already the planned cross-session/task layer (right call —
nothing in the GPT notes beats it); no other external planner earns a slot. The plan
*format* stays plain markdown in-repo so Cursor/Antigravity agents consume it identically.

## 4. Draft: `.claude/commands/make-plan.md`

To ship (with a genericised mirror in `templates/.claude/commands/`) once §5's ADR-0003
question is settled. Draft:

```markdown
---
description: Investigate the repo and produce a decision-ready implementation plan in work/NNNN-slug/ — planning only, no production edits. For changes big enough that the plan must outlive the session.
argument-hint: <feature, problem, or desired outcome>
---

# Make a plan

Produce a reviewable implementation plan for: $ARGUMENTS

**Planning only.** Do not modify production code, schemas, dependencies, CI, or anything
externally visible. The only files you may create are the plan artifacts and draft ADRs
named below.

## Ground rules

- Repo evidence over assumption. Never claim a file, API, or convention exists without
  verifying it in the tree or git history.
- If sources conflict (AGENTS.md vs code vs an ADR), record the conflict — don't
  silently pick a side.
- Ask clarifying questions only when the answer materially changes scope, architecture,
  security, persistent data, public contracts, or acceptance criteria. Otherwise
  investigate first.
- Label every significant statement: **Confirmed** (verified in repo/task),
  **Inferred** (plausible, needs validation), or **Needs-decision** (human must choose).

## 1. Orient

Read, in order: the root `AGENTS.md` (and any nested one covering the affected area);
`ARCHITECTURE.md` if the repo keeps one; ADRs that constrain this area; `work/` for
overlapping in-flight items; then the relevant implementation, tests, and recent git
history. Fan wide investigation out to Explore subagents rather than serially reading
everything yourself. Summarize only the facts that shape the plan.

## 2. Where the plan lives

- If the repo keeps `work/`: create `work/NNNN-slug/` (next free number) with `plan.md`,
  plus `spec.md` first if the "what/why" needed pinning down. The exit rule applies:
  this folder is deleted or archived when the work merges.
- If the repo has its own planning location, use that. If it has neither, ask where the
  plan should live — don't invent a new top-level directory.
- If the repo uses beads (`.beads/` present): file the task breakdown as a bd epic with
  dependent tasks, link the epic ID from `plan.md`, and do **not** leave a parallel
  markdown checklist. Otherwise, include the task breakdown as a section of `plan.md` —
  that is the complete workflow, not a degraded one. Never install beads or suggest
  adopting it; whether a repo uses bd is a per-repo decision already made elsewhere.

## 3. plan.md contents

Problem and intended outcome · verified evidence and constraints · scope and explicit
non-goals · assumptions and open questions (classified) · proposed design and
alternatives considered · ordered file-level implementation steps · data/API/config
compatibility and migration effects · security, reliability, and rollback
considerations · validation plan (the actual commands) · acceptance criteria ·
risks and sequencing · task breakdown (or the bd epic link).

Be specific enough that a separate session can execute one task without rediscovering
the architecture. State "none identified" only after actually looking.

## 4. Consequential decisions → draft ADRs

If a choice affects public contracts, persistent data, security boundaries, core
architecture, or cross-repo conventions, draft a `Proposed` ADR in `docs/adr/` (repo's
template and numbering) instead of burying the rationale in the plan. Local
implementation details never get ADRs.

## 5. Approval gate — always stop here

Do not implement. End with: the plan path · a one-paragraph recommendation · key
verified findings · the decisions needing approval (only those) · blocking questions,
if any · the suggested first task once approved.
```

## 5. Structure suggestions surfaced by this investigation (for discussion)

**a) The skill/command convergence touches ADR-0002.** Claude Code now treats
`.claude/commands/*.md` as legacy and recommends `SKILL.md` with
`disable-model-invocation: true` for human-invoke-only procedures — the ADR-0002 fork
becomes a frontmatter flag rather than a directory choice. Nothing breaks today
(commands still work), but when EXAMPLE_SKILLS_PLAN's example skills ship, we should
decide in one ADR whether `/wrap-up` and `/make-plan` migrate to skill form, and how
that squares with the scaffold's cross-tool `.agents/skills/` slot. Until then, shipping
`/make-plan` as a command keeps the repo consistent with ADR-0002.

**b) Where plans live needs its own ADR (ADR-0003).** Three forces meet: the scaffold's
`work/` tier (opt-in, with exit rule), beads' "no markdown plan directories" rule, and
plan mode's new `plansDirectory`. Proposed reconciliation, to be recorded: *design-layer
plans live in `work/NNNN-slug/` under the exit rule; execution tracking lives in beads;
the beads "retire plans/" rule applies to task checklists, not design docs* — this is
already implicit in the beads coexistence table but should be stated once, canonically.

**c) `plansDirectory` in the settings template.** Optionally add
`"plansDirectory": "./work/plans"` (gitignored) to `templates/.claude/settings.json` so
ad-hoc plan-mode output stops evaporating in `~/.claude/plans/`. Cheap, reversible,
worth considering alongside b).

**d) `docs/incoming/` has no home.** It's not in the AGENTS.md index and has no
lifecycle. Suggest: an index line plus an exit rule mirroring `work/` — an incoming note
gets distilled into a real doc/ADR (as this one does for the GPT notes) and is then
deleted or archived. Otherwise it becomes exactly the stale-context trap the reference
warns about.

**e) The `docs/*_PLAN.md` pattern is an informal RFC tier.** BEADS_ADOPTION_PLAN,
EXAMPLE_SKILLS_PLAN, and now this file are proposals-under-discussion — the scaffold's
`docs/rfcs/` role. Either bless the current pattern with an index line ("drafts under
discussion → docs/*_PLAN.md") or adopt `docs/rfcs/` for real. Low urgency; worth
settling before a fourth one appears.
