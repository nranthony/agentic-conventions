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
The evidence is the first full triage run, the same day (ADR-0020, Context): a procedure
rebuilt from four documents, a signature that could not travel through a subagent, untracked
reports blocking the channel publish, and a release and consume tail worked out by hand.

What that run left on the host, in order:

| Step | Why it is on the host |
|---|---|
| Push the channel and every member with new commits | remote git is denied in the sandbox |
| On the Mac: `tools-check`, `vendor-tools`, `tools-check`, `converge` per profile | the sandbox tool's repo is not reachable from a container |
| Restart the agents in every running container | new skill text loads at start |
| Carry the handbacks to the Mac's sandbox tool | it has no inbox; no container reaches it |
| Everything on the Win11/WSL2 machine | a different machine; nothing here reaches it |

The first and third rows cannot be removed from inside the sandbox, and neither can the
signature. The rest can be reduced to one block, composed without guessing.

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

1. **A catch-up skill for the Win11/WSL2 sandbox**, to pick up what is released and changed
   on the Mac. Designed next. Known constraint: its container sees only its channel clone,
   and the channel's `inbox/` is gitignored, so a handoff delivered there on the Mac never
   reaches that machine.
2. **One consume recipe on the Mac's sandbox tool**, turning the four-command loop into one:
   `handoff-macolima-consume-recipe.md`, human-ferried. A proposal to that repo, not a
   request — its own rules decide.
3. **`work/0024`** (a triage gate for `clickup-pull`) is still owed a signature; the skill
   presents it on its first run.

Exit rule: archive when 0.11.0 is consumed on both machines and open items 1 and 2 have
landed or been declined.

## Alternatives

Recorded in ADR-0020.
