# ADR-0005: Adopt docs/rfcs/ as the proposal tier

- Status: Superseded by [ADR-0006](0006-proposals-are-work-items.md)
- Date: 2026-07-31
- Deciders: nranthony + agent

## Context

Proposals-under-discussion had accumulated informally as `docs/*_PLAN.md` files
(beads adoption, example skills, planning toolkit). On 2026-07-31 that pattern was
briefly blessed with an AGENTS.md index line as an "informal RFC tier" — then
reconsidered the same day: the reference scaffold already defines `docs/rfcs/` with a
real status lifecycle (`Draft → In review → Accepted → ADR-NNNN | Rejected`), it is
the widely recognized convention collaborators know, and the provenance chain names it
("an RFC proposes → an ADR records"). Picking one convention to keep long-term, the
formal, more widely adopted tier wins — and the scaffold's warning against empty
ceremony dirs doesn't apply, since three live proposals already occupy the tier.

## Decision

**Proposals live in `docs/rfcs/`**, one file per proposal with the scaffold's RFC
status header; `TEMPLATE.md` sits in the directory. The three `*_PLAN.md` drafts are
migrated as `rfcs/beads-adoption.md` (Accepted, in rollout), `rfcs/example-skills.md`
(Draft), and `rfcs/planning-toolkit.md` (Accepted → ADR-0003/0004). An accepted RFC's
rationale moves into an ADR; the RFC's status line links it. The `docs/*_PLAN.md`
pattern is retired.

RFCs are durable discussion records in `docs/` — not `work/`, whose contents are
in-flight implementation artifacts deleted on merge.

## Consequences

- This repo now dogfoods the scaffold's full provenance chain: RFC → ADR → work/ →
  commit.
- AGENTS.md indexes `docs/rfcs/` instead of the `*_PLAN.md` glob.
- Future proposals start from `docs/rfcs/TEMPLATE.md`; no fourth `*_PLAN.md` appears.

## Alternatives considered

- **Keep `docs/*_PLAN.md` (the same-morning blessing):** rejected — ad-hoc status
  headers, unrecognizable to collaborators, and a second convention to explain when
  `docs/rfcs/` already exists in the blueprint.
- **`work/rfcs/`:** rejected — `work/` carries an exit rule (delete on merge);
  proposals need to persist as discussion records after resolution.
