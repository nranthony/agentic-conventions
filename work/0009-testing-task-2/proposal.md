# Proposal: testing task 2

- Status: Draft — **BLOCKED, do not start**
- Author: nranthony + agent
- Synced: 2026-08-11 — pulled

- ClickUp: 86bbc89yp — https://app.clickup.com/t/86bbc89yp
- ClickUp-status: to do
- ClickUp-path: Codebase / Agentic Conventions
- ClickUp-parent: 86bbc89p1 — "Continue Clickup Sync testing" (pulled as subtask 2 of 2)
- ClickUp-blocked-by: 86bbc8ahm — "Continue ClickUp Sync testing blocker" — not pulled, status: in reveiw

## From ClickUp

> *(no description)*

## Summary

Test fixture: the blocked half of the fan-out. `86bbc8ahm` blocks this task and its status
`in reveiw` is `status_type: custom` — **not** `done`/`closed` — so the blocker gate fires
and work on this item must not begin.

## Motivation

This is the first live exercise of the rule that makes the dependency graph actionable
rather than decorative: a blocker that is not `done`/`closed` stops the work, and the gate
re-reads live rather than trusting this snapshot.

## Proposal

Do not start. When the blocker closes, re-read it live (`myclickup task 86bbc8ahm`) and
confirm `status.type` is `done` or `closed` before proceeding — the `in reveiw` above is a
snapshot, not authority.

## Open questions

None.

## Alternatives

None — fixture.
