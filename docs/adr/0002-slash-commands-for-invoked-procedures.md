# ADR-0002: Slash commands for deliberately-invoked procedures

- Status: Accepted
- Date: 2026-07-21
- Deciders: nranthony + agent

## Context

Some procedures are worth capturing but should fire only when a human decides they're
warranted — the motivating case is an end-of-thread wrap-up that cross-checks the
provenance trail (AGENTS.md/CLAUDE.md stubs, ADRs, work/, skills, CHANGELOG) before a
thread is compacted or cleared. It's the right move for a complex thread that bounced
across several issues; it's pure overhead on a simple one.

Two homes were candidates:

- **A skill** (`.agents/skills/<name>/SKILL.md`) auto-discovers and auto-triggers on its
  `description`. That is exactly wrong here: the procedure is heavyweight and only
  sometimes wanted, and "before I compact/clear" is a fuzzy trigger that would either
  misfire or sit inert.
- **A slash command** (`.claude/commands/*.md`) is a saved prompt the human invokes by
  name. Nothing auto-loads or auto-applies it.

The open question was whether this collides with [ADR-0001](0001-reference-not-automation.md),
which removed all file-writing automation from this repo. It does not: a slash command
mutates nothing on its own — it expands into a prompt an agent then executes under the
same review as any other turn. It is advice, not enforcement.

## Decision

Adopt `.claude/commands/*.md` as a supported slot in this repo for procedures meant to be
**invoked deliberately, not auto-triggered.** The first command is
`.claude/commands/wrap-up.md` (`/wrap-up`).

The command is written to *propose* direction-setting changes (new ADRs, supersessions)
and only *apply* mechanical fixes (stale links, missing `CLAUDE.md` stubs) — consistent
with ADR-0001's "reference, not automation" stance. A generic copy is mirrored into
`templates/.claude/commands/` as example content, and the reference notes the slot.

## Consequences

- The repo gains a `.claude/commands/` directory and dogfoods the slot the reference
  previously only listed in passing.
- Procedures now have a clear fork: **auto-invoke → skill; human-invoke → slash command.**
- Does not reintroduce the ADR-0001 footgun class — commands write nothing by themselves.
- Consumer repos get a ready-to-adapt `/wrap-up` via the template mirror.

## Alternatives considered

- **Package it as a skill:** rejected — auto-triggering a heavyweight, only-sometimes-
  wanted procedure is the wrong behavior, and the trigger phrase is unreliable.
- **Leave it as an ad-hoc prompt pasted per session:** rejected — not reusable, not
  discoverable, and drifts every time it's retyped.
