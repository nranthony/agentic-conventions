# ADR-0020: Feedback triage ships as a skill, and the signature is the owner's answer in that session

- Status: **Accepted**
- Date: 2026-09-15
- Deciders: nranthony (owner, signed in-session on 2026-09-15) + agent
- Extends: ADR-0013 §4 (the triager and signer roles) and ADR-0016 (feedback is tracked and
  routed to the owning repo). Tracked in
  [work/0025](../../work/0025-triage-skill-feedback/proposal.md).

## Context

ADR-0013 split the feedback channel into three roles — reporter, triager, signer — and
shipped a skill for exactly one of them. The reporter has had
`/myconv:report-skill-feedback` since 0.6.0. The triager has had a sentence in `AGENTS.md`
and a ledger header.

The first full triage run, on 2026-09-15, worked two `pipeline` reports about
`clickup-pull` through to myconv 0.10.0. It showed what that sentence leaves to be
rediscovered each time:

- **The procedure was rebuilt mid-run** from ADR-0013, ADR-0016, `feedback/README.md` and
  `AGENTS.md`: where reports wait, the upward-only reclassification rule, archive-never-
  delete, the ledger row, the CHANGELOG line that serves as the reply.
- **The signature went to the wrong place.** Triage was delegated to a subagent. The owner
  had chosen "triage and fold what survives into 0.10.0", and the subagent — correctly —
  declined to treat that relayed instruction as a signature on the direction-setting
  report, which was parked as `work/0024`. The outcome was right and the shape was wrong:
  the owner was in the session the whole time, one question away.
- **The reports blocked the release.** They arrived untracked mid-session, and the
  channel's clean-tree check counts untracked files, so nothing could be published until
  someone decided what they were.
- **The release tail and the host tail were worked out by hand** — both version
  manifests, the plugin sync, the gate, the commit, the channel publish, verify and commit
  on one side; on the host, the owner found the consume steps by reading the sandbox tool's
  recipe list.

The procedure is not this repo's alone. myclickup's `AGENTS.md` describes the same triage
and keeps the same ledger, with one variation this repo had not needed: a report **split
along an artifact boundary** (2026-08-25 — its skill note mechanical, the CLI surface it
implied direction-setting).

## Decision

**1. Triage ships as `/myconv:triage-skill-feedback`**, canonical at
`.claude/skills/triage-skill-feedback/` and carried in the plugin like the other shared
skills. It is user-invoked only (`disable-model-invocation: true`): it commits, and it
publishes.

**2. The signature is the owner's answer to a question asked by the session running
triage.** It is never relayed through a subagent, and never inferred from an earlier
approval of something else. A run with no human present parks each direction-setting
proposal in the owning repo's pre-decision surface and applies nothing from it. This is
what ADR-0013 §4's "the human signs" looks like in practice; who signs does not change.

**3. One run goes from waiting reports to a released state**: preflight, intake, verify,
decide, record, release through the owning repo's gate and the channel, and one closing
block of host-side steps.

**4. The skill follows the owning repo** (ADR-0015): where a direction-setting proposal
waits, which files a version bump touches, what the gate is. Splitting a report along an
artifact boundary is allowed; carving pieces off one direction-setting edit is the
downward reclassification ADR-0013 §3 forbids.

**5. The host block quotes recorded procedure and never invents a host command.** A
channel that wants a complete block has to document how its releases are consumed, per
machine.

## Consequences

- **Some steps stay on the host, and the skill does not pretend otherwise:** pushing, the
  signature, the re-vendor on each machine, restarting the agents. What the skill removes is
  everything between "a report exists" and "one block to paste". Shrinking the block
  further is a sandbox-side change — a single consume recipe — proposed to the Mac's
  sandbox tool in `work/0025`.
- **The shipped skill count goes from six to seven.** `AGENTS.md`, the README, the
  marketplace description, the `justfile` comment and the ledger header are updated.
  ADR-0013 and ADR-0015 still say "five skills": they are append-only records of the day
  they were written.
- **The reporter's "What happens to your report" names the triage skill.**
- **The first owed signature is `work/0024`** (a triage gate for `clickup-pull`), which
  the skill's preflight will list on its first run.
- **This record reopens** if the signer's answer ever has to be given somewhere the triage
  session cannot ask — a surface with no human in the loop at all.

## Alternatives considered

- **Keep triage a manual procedure.** Rejected on the evidence above: every step the run
  rebuilt by hand is a step the next run rebuilds again.
- **An internal skill in this repo, never shipped** (as myclickup keeps `/handoff`).
  Rejected: `just sync-plugin` ships every `.claude/skills/*/` today, so it would need an
  exclusion; and myclickup triages the same way and would go without.
- **A skill in the channel repo.** Rejected: triage belongs to the repo that owns the text
  (ADR-0016). The channel publishes; it does not decide what a skill says.
- **Let the triager decide direction-setting reports that look small.** Rejected:
  ADR-0013 §3 exists so that a report cannot be merged a piece at a time without the human
  seeing it.
- **Always park direction-setting reports as proposals.** Rejected by the owner: an answer
  given in the session costs a question, is still the human's, and does not leave a queue
  of proposals for a later sitting.
