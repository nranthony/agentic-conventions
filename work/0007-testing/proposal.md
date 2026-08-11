# Proposal: 0006 - testing

- Status: Draft
- Author: nranthony + agent
- Synced: 2026-08-11 — pulled

- ClickUp: 86bbc7we3 — https://app.clickup.com/t/86bbc7we3
- ClickUp-status: ready for agent
- ClickUp-path: Codebase / Agentic Conventions

## From ClickUp

> creating a new ClickUp workspace and task that moves into the ready for agent state for testing in work item six

## Summary

Smoke-test of the ClickUp → `work/` pull path defined in ADR-0008. This item exists to
prove the machinery, not to carry work of its own.

## Motivation

Everything in `work/0006-clickup-work-sync/` was reasoned from the ClickUp API shape and
the `myclickup` source without ever being run. This is the first live exercise of it.

## Proposal

Pull this task, inspect what the skill produced, and fix whatever the run exposes.

## Open questions

None — see `work/0006-clickup-work-sync/notes.md` for what the run found.

## Alternatives

None. This is a test fixture; delete or archive it once 0006's findings are folded in.
