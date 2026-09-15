# Proposal: ship feedback triage as a skill, and end every run in one block of host steps

- Status: Accepted → [ADR-0020](../../docs/adr/0020-feedback-triage-is-a-shipped-skill.md) —
  signed by the owner in-session, 2026-09-15
- Author: agent, at the owner's request of 2026-09-15

## Summary

Ship `/myconv:triage-skill-feedback`, the receiving half of the feedback channel: in the
repo that owns a skill, it takes waiting reports from claim to release in one run, asks the
owner in that session for every direction-setting decision, and ends with a single block of
the steps only the host can do.

## Motivation

The owner asked for triage to run inside the sandbox with as few host steps as possible.
The evidence, and what it rules in and out, is ADR-0020's Context. The host steps that
remain are written once, in the channel's `AGENTS.md` under "Consuming a release".

## Proposal

The owner's four answers, as signed:

1. **A new myconv skill**, shipped in the plugin — not an internal skill, and not a channel
   skill. myclickup follows the same triage and gets it too.
2. **The in-session answer is the signature**, asked by the session talking to the owner;
   a headless run parks the proposal instead.
3. **One run goes through publish** and ends in one host block plus any ferry-ready
   handback.
4. **The Win11/WSL2 container sees only its channel clone.** That constrains the second
   skill (below), not this one.

The skill itself is `.claude/skills/triage-skill-feedback/SKILL.md`. Its closing block
quotes the channel's own record of how a release is consumed, so that record was written
into the channel's `AGENTS.md` alongside this change, with the Mac's steps as the owner ran
them on 2026-09-15.

## Open items

1. ~~A catch-up skill for the Win11/WSL2 sandbox~~ — **done 2026-09-15**, as the channel's
   internal `/catch-up` (`depot/.claude/skills/catch-up/`). No ADR and no work item of its
   own: it decides nothing for any member, and reads existing records rather than
   restating them.
2. **One consume recipe on the Mac's sandbox tool**, turning the four-command loop into one:
   `handoff-macolima-consume-recipe.md`, human-ferried. A proposal to that repo, not a
   request — its own rules decide.
3. **`work/0024`** (a triage gate for `clickup-pull`) is still owed a signature; the skill
   presents it on its first run.

Exit rule: archive when 0.11.0 is consumed on both machines and open items 1 and 2 have
landed or been declined.

## Alternatives

Recorded in ADR-0020.
