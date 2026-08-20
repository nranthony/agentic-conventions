# ADR-0013: A one-way feedback channel for the shared skills

- Status: Proposed
- Date: 2026-08-20
- Deciders: nranthony + agent (Fable 5)
- Distilled from: `work/0017-skill-feedback-loop/proposal.md` (Draft, 2026-08-18), and
  the two worked instances recorded there and in `work/0018-clickup-pull-conformance/`.

## Context

The five shared skills run in places their author cannot see: the member repos, the
container sandbox's vendored copy, and — if export ever resumes — shell-less surfaces.
An agent that finds a skill's instructions wrong, stale, or a bad fit for its repo has
had exactly one option: work around it and move on. The failure is silent, it happens
precisely where the information is, and the information is destroyed at that moment —
the workaround produces good output, so nothing downstream ever looks anomalous. No
grader, trace, or output check can recover it; only the deviating agent knows.

This is not hypothetical. In two days, two reports crossed by hand through
conversations: eight defects in `/clickup-pull` from the `myclickup` repo
(work/0018), and a blueprint gap from the `numerai` repo that had already shipped a
dead instruction into a live sandbox notice (work/0017, second worked instance). Both
were actionable; both cost a human ferrying them; and both would have been cheaper,
better-provenanced, and faster with a channel.

Two facts shape the design:

- **Nobody can tell which text ran** without provenance on the report — the
  container's copy is whatever the last image build baked in, and triage otherwise
  starts with "was this fixed weeks ago?".
- **Our guardrails live inside the skills a report can propose edits to.** A channel
  that accepts proposed diffs to skill text accepts proposed diffs to its own
  constraints, and a gate inside the material it gates does not hold.

## Decision

Build a one-way inbound channel: **a report must be actionable on arrival with no
reply, and no response is guaranteed.** The consumer unblocks itself locally
regardless. Concretely:

1. **Transport reuses the doorbell.** The reporting agent writes the report into its
   own repo first (the tracked original is the record), then copies it to this repo's
   gitignored `inbox/` as `<repo>-<skill>-<date>-<slug>.md`. Acting on a report means
   promoting it to a `work/NNNN-slug/` item or an ADR, then deleting the doorbell
   file. Consumers that cannot reach this repo (the deployment tier, shell-less
   surfaces) write the file locally and name the copy as a human-ferried step.
2. **The envelope is owned by one skill** (`report-skill-feedback`); the other skills
   carry a two-line pointer to it at the point of deviation, plus one sweep question
   in `/wrap-up`. Required fields: which text ran (the generated `VERSION` sidecar —
   shipped, myconv 0.6.0); which artifact is wrong (skill / blueprint / template /
   ADR); the step it broke at, quoted by heading; a proposed edit, not a description;
   a generic / conditional-on-X / local-to-me verdict with the repo-shape evidence;
   and a risk class.
3. **Risk class is drawn by effect, not artifact.** *Direction-setting* means the
   edit would change what a guardrail, an ADR, or the blueprint **decides**; it
   routes to the ADR-first lane and is never merged from a report alone.
   *Mechanical* means the edit follows from what is already decided — a wrong path, a
   stale command, a clarification — wherever the text lives, the blueprint included.
   The reporter's class is a claim: a triager may reclassify upward, never downward.
   (The by-artifact draft in the proposal routed every blueprint edit ADR-first; its
   own first live report — a content clarification to the blueprint — proved that
   line wrong.)
4. **A proposed diff is a claim, not a patch.** Triage may reword, and the first live
   report needed exactly that: its rule as proposed would have banned legitimate
   notice content; the shipped rule kept its failing example failing.
5. **Consumer copies are read-only.** A deviation is recorded in the consumer's repo
   and filed upstream — never silently patched into the vendored copy, which turns
   drift invisible.
6. **The loop closes in `CHANGELOG.md`**: when a report becomes a change, the entry
   names the report it came from. Feedback with no observable outcome stops arriving.
7. **A leak rule**: minimum excerpt, no client names, no identifying paths — a report
   copies context out of a possibly-private repo into this one.

## Consequences

- The channel is cheap where it must be (files, git, an existing doorbell) and adds
  no state machine, no SLAs, no telemetry. The cost accepted is fidelity: one-way
  means an under-specified report may die unactioned, by design.
- The envelope's burden falls on the reporter — deliberately. A proposed diff and a
  verdict-with-evidence force reading the skill rather than describing a feeling.
- The risk-class line ("by effect") demands judgment rather than a filename match; the
  reclassify-upward-only rule is what keeps that judgment safe. The gate stays
  outside the substrate: direction-setting changes reach a human through the ADR lane
  no matter what any skill text says.
- `inbox/` remains gitignored, so an unpromoted report vanishes with the checkout.
  Acceptable: the tracked original lives in the sender's repo.
- The prior-art survey behind the proposal remains uncited here — its sources could
  not be verified from inside the sandbox (attempted 2026-08-20; the web broker's
  quota and allowlist both said no). This ADR stands on the two worked instances. If
  the sources later check out, they corroborate; nothing in this decision depends on
  them.

## Alternatives considered

- **Do nothing; the owner notices.** Already false — the two hand-carried reports are
  the counterexample, and the second found a defect that had shipped.
- **A tracked `feedback/` directory here.** A second work-tracking surface with no
  lifecycle, competing with `work/`. Rejected.
- **ClickUp as the inbound surface.** A foreign consumer has no client on PATH and no
  pinned workspace; files travel where API calls do not. A surviving report can still
  be promoted to the board as a work item.
- **A reply channel.** Higher fidelity per report, and precisely the round-trip cost
  the design exists to remove.
- **Self-rewriting instructions** (skills that edit themselves from feedback
  signals). Out under the reference-not-automation decision (ADR-0001), and out on
  its own merits: the gate must sit outside what a report can change.
