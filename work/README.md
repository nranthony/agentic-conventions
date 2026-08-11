# work/ — proposals and in-flight items

One numbered folder per unit of work — proposals included ([ADR-0006](../docs/adr/0006-proposals-are-work-items.md)).
`NNNN` is the next free number across active **and** archived items; numbers are never
reused. This directory is the answer to both "what's proposed?" and "what's in flight?".

## Files inside an item

Each is optional except whichever one starts the item:

- `proposal.md` — "should we do this?" (status-tracked; template below)
- `spec.md` — the pinned what/why, when it needs pinning
- `plan.md` — the implementation plan (typically via `/make-plan`)
- `notes.md` — running notes while executing

## Lifecycle and exit rule

1. An item opens as a `proposal.md` (Draft) or, for pre-decided work, straight as a
   `spec.md`/`plan.md`.
2. An accepted proposal's durable rationale is **distilled into an ADR** in
   [docs/adr/](../docs/adr/); the proposal's status line links it
   (`Accepted → ADR-NNNN`). Reference knowledge distills into `docs/` or a skill.
3. When the work merges or the question resolves, the folder moves to `work/archive/`
   (committed). Pure-implementation items with nothing durable left in them may be
   deleted instead. **Nothing durable may live only in `work/`.**

Archived items are historical records: never treat an archived `proposal.md` or
`plan.md` as current intent — the distilled ADR is canonical.

`work/plans/` is gitignored scratch space for native plan-mode drafts
(`plansDirectory`); a draft becomes durable by promotion into an item.

## External tracker link (optional)

An item may point at a ClickUp task — the two are separate projections of one piece of
work, not duplicates ([ADR-0008](../docs/adr/0008-clickup-work-sync.md)). The pointer
lives in the item's front-matter and is created by `/clickup-pull`:

```markdown
- Synced: 2026-08-11 — pushed: Agent Working
- ClickUp: 86abc123 — https://app.clickup.com/t/86abc123
- ClickUp-status: Agent Working
- ClickUp-path: <Space / Folder / List>
- ClickUp-blocked-by: 86dep001 — "Vendor API credentials" — not pulled, status: To Do
```

Two rules carry the weight: it is a **snapshot, not a mirror** (a gate decision re-reads
live), and a blocker that is not `done`/`closed` **stops the work**. Reporting back
(`/clickup-report`) is limited to a status change and a short comment — plans and notes
never cross.

## Proposal template

```markdown
# Proposal: <title>

- Status: Draft | In review | Accepted → ADR-NNNN | Rejected
- Author: <name / agent>

## Summary
## Motivation
## Proposal
## Open questions
## Alternatives
```
