# ADR-0006: Proposals are work items; docs/rfcs/ is retired

- Status: Accepted
- Date: 2026-08-06
- Deciders: nranthony + agent
- Supersedes: [ADR-0005](0005-adopt-rfcs.md) (the `docs/rfcs/` tier; the principle
  that proposals precede ADRs and persist after resolution survives)

## Context

ADR-0005 adopted `docs/rfcs/` as the proposal tier six days ago. Real usage since —
here and in other repos following these conventions — favors a **single numbered
in-flight pipeline** over a separate proposal directory:

- **The tier duplicated itself.** An accepted RFC's rationale moves into an ADR
  (ADR-0005's own rule), leaving the RFC file a near-duplicate historical shell —
  `planning-toolkit.md` ended as 200 lines whose status header says "the shipped
  skill is canonical."
- **Two numbering/status systems to explain.** ADR numbers plus RFC slugs, each with
  its own lifecycle, for a repo whose value is having *one* obvious home per question.
- **At this repo's scale (solo owner + agents), no discussion happens in-file.**
  Discussion happens in-session; the durable outcome is the ADR. The RFC tier's real
  audience — collaborators reading proposals asynchronously — doesn't exist here.
- **Proposal and implementation want to be co-located.** A proposal that's accepted
  immediately grows a spec/plan/notes; splitting those across `docs/rfcs/` and
  `work/NNNN-slug/` gives agents two places to check for "what's in flight on this."

ADR-0005 rejected `work/` as the proposal home because its exit rule (*delete* on
merge) would destroy discussion records. That objection is answered by revising the
exit rule for proposal-bearing items: **distill, then archive** — never bare-delete.

## Decision

**`work/NNNN-slug/` is the single numbered pipeline for everything in flight,
proposals included.** `docs/rfcs/` is removed.

- An item that starts as a proposal begins as `work/NNNN-slug/proposal.md` with the
  status header `Draft | In review | Accepted → ADR-NNNN | Rejected`. If accepted,
  `spec.md` / `plan.md` / `notes.md` grow in the same folder.
- **Exit rule (revised from ADR-0003's delete-or-archive):** before an item closes,
  anything durable is distilled out — decision rationale into an ADR, reference
  knowledge into `docs/` or a skill — then the folder moves to `work/archive/`
  (committed). Pure-implementation items with nothing durable may still be deleted.
  Numbers are never reused.
- `work/README.md` documents the lifecycle and carries the proposal template
  (replacing `docs/rfcs/TEMPLATE.md`).
- The reference scaffold adopts the same shape, keeping a classic `docs/rfcs/` as a
  **noted alternative for team-scale repos** where humans genuinely discuss proposals
  asynchronously in-file.

Migration of the five existing RFCs (numbered by original recording date):

| Was | Now |
|---|---|
| `docs/rfcs/example-skills.md` (Draft) | `work/0001-example-skills/proposal.md` |
| `docs/rfcs/planning-toolkit.md` (Accepted, implemented) | `work/archive/0002-planning-toolkit/proposal.md` |
| `docs/rfcs/skills-beyond-this-repo.md` (Draft) | `work/0003-skills-beyond-this-repo/proposal.md` |
| `docs/rfcs/gloss-before-cite.md` (Draft, uncommitted) | `work/0004-gloss-before-cite/proposal.md` |
| `docs/rfcs/beads-adoption.md` (Accepted, in rollout) | `conventions/beads/ADOPTION.md` — a cross-repo playbook, not a proposal; its own §2.3 always named this location |

Next free item number: 0005.

## Consequences

- One numbered sequence, one lifecycle, one place to look for anything not yet merged;
  ADRs remain the only durable decision record.
- `AGENTS.md`, the reference scaffold, `templates/`, and the `/wrap-up` + `/make-plan`
  skills are updated in the same change; downstream repos that adopted `docs/rfcs/`
  can migrate at their own pace (the scaffold still documents the shape).
- Links to `docs/rfcs/*` inside older append-only ADRs are fixed mechanically to the
  new paths (link maintenance, not decision rewriting); anything else resolves via the
  mapping table above or git history.
- `work/` is no longer purely ephemeral: `work/archive/` is committed history. Archived
  items are historical records — agents must not treat an archived `proposal.md` as
  current intent; the distilled ADR is canonical.

## Alternatives considered

- **Keep `docs/rfcs/` (status quo, ADR-0005):** rejected — at this scale it's a
  duplicated tier whose files go stale the moment their rationale moves to an ADR.
- **Keep both tiers (RFCs for conventions, work items for implementation):** rejected —
  two homes for "what's proposed" is exactly the ambiguity this repo exists to remove.
- **Delete proposal folders on completion (unmodified ADR-0003 exit rule):** rejected —
  destroys discussion records; ADR-0005's objection was valid, so the exit rule
  changed instead.
