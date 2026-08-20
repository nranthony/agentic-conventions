# Proposal: an inbound feedback channel for the shared skills

- Status: Draft
- Author: nranthony + agent (Opus 5)
- Opened: 2026-08-18
- Related: **[work/0018](../0018-clickup-pull-conformance/proposal.md)** — read it
  alongside this. It is a worked instance of the traffic this channel is for: eight
  defects in `/clickup-pull`, reported by a consuming agent in the `myclickup` repo and
  carried back by hand through a conversation. Every guardrail proposed here can be
  tested against it — does the envelope schema hold what that report actually carried,
  and would its risk class have been assigned correctly? (Added 2026-08-18 by the 0018
  author. Both items opened as `0017` within minutes; 0018 yielded the number.)
- **A second worked instance** (added 2026-08-20): the `numerai` notice-paths report —
  see the section of that name below. It arrived while this channel is still a Draft,
  crossed by hand exactly as 0018's traffic did, and its triage surfaced a defect in
  §2's risk-class definition. Its human-ferried remainder is
  [handoff-sandbox-notice-paths.md](handoff-sandbox-notice-paths.md), tracked in this
  folder.

## Summary

Give agents that *use* the shared skills a way to report back when a skill's
instructions were wrong, stale, or a bad fit for the repo they were running in — without
opening a conversation. One folder (the existing `inbox/` doorbell), one envelope
schema with a single home (a sixth skill), and a set of guardrails whose whole purpose is
that a report is actionable **on arrival, with no reply**. The design goal is not
"collect feedback"; it is "never round-trip".

Two constraints shape everything else. A report must carry enough to be acted on without
a reply, or the channel costs more than the silence it replaces. And because our
guardrails live inside the skills a report can propose edits to, every report declares a
risk class — so a proposed change to a rule can never arrive looking like a typo fix.

## Motivation

Five skills ship to consumers we cannot see: this repo, the other member repos in the
channel, the container sandbox's vendored copy, and — if the on-hold export work
(`work/0003-skills-beyond-this-repo/proposal.md`) resumes — claude.ai and Desktop. Today a
consuming agent that finds a skill wrong has exactly one option: edit around it and move
on. That failure is silent, it is where the information was, and it is gone.

Two things make the naive version of this ("just tell me what broke") expensive:

1. **We cannot tell which text actually ran.** The container's copy is whatever the last
   image build baked in, not what `.claude/skills/` says today — the same hazard the
   channel already warns about for the vendored client
   (`depot/AGENTS.md`: never verify behaviour with the in-container binary while a
   re-vendor is outstanding). Without a version on the report, a large share of triage is
   discovering the complaint was fixed upstream weeks ago.
2. **Most reports are really a tier question.** "The skill is wrong" and "the skill does
   not suit my repo" look identical in prose and want opposite fixes — one edits the
   canonical skill, the other belongs in the consumer's own `AGENTS.md`. The tiers are
   already named in [README — Tiers](../../README.md#tiers-what-does-not-belong-here);
   the envelope has to make the reporter answer with evidence rather than leave it for a
   reply.

Both are round trips, and a channel that round-trips twice per report will not be used.

## Proposal

Roughly ordered by effort/value; 1–3 are the channel, 4 is what makes it survive, 5 is
cheap insurance before any of it ships.

### 1. Transport — reuse the doorbell, do not invent one

The cross-repo handoff pattern already works and is already proven across two member
repos: the **tracked original lives in the sender's repo, and the copy in the receiver's
`inbox/` is only a doorbell** (see `inbox/myclickup-0013-status-vocabulary-transfer.md`
for a live example of the shape).

- The consuming agent writes the report into **its own repo** first — inside the work
  item it had open, or a small `feedback/` folder if it had none. That copy is tracked,
  and it is the record.
- It then copies the file to `<conventions>/inbox/<repo>-<skill>-<date>-<slug>.md`. The
  filename convention makes the folder self-sorting by consumer and by skill.
- `inbox/` is gitignored here, so the existing exit rule applies one level earlier:
  **nothing durable may live only in the inbox.** Acting on a report means promoting it
  to a `work/NNNN-slug/` item or an ADR, then deleting the doorbell file.

Two consumer classes cannot perform the copy: the deployment tier
(`windows-ai-sandbox` lives on the host and no container reaches it) and any shell-less
surface such as claude.ai. For those the skill writes the file locally and says
plainly that it is a human-ferried step — the same rule the channel already applies to
anything touching the vendored wheel, the skill text, the image, or the allow-list.

**Not proposed:** a tracked `feedback/incoming/` directory in this repo. It would
accumulate reports whose status nobody maintains, and it duplicates the job `work/`
already does.

### 2. The envelope — the fields that remove a round trip

Three questions cause nearly all of the back-and-forth. Each gets a field, and the fields
are machine-captured wherever they can be — the channel's rule that hashes and permission
data are generated rather than transcribed applies to a report's provenance for the same
reason.

**Which text ran.** Stamp the payload at generation time. `just sync-plugin` is already a
generator, so have it write a `VERSION` sidecar — plugin version plus a short hash of the
`SKILL.md` — into each payload skill directory. Every copy then self-identifies with no
runtime path discovery, which is what makes it work on the container copy and on a
shell-less surface alike. Cost: both directory comparisons need the exclusion the
vendored check already uses for `variants/` — `diff -r -x variants -x VERSION`
(`justfile:121`, and the plain `diff -r` in `check-plugin-sync`).

**Whose problem it is.** The reporter states which repo-shape fact the skill assumed — a
`justfile`, a `work/NNNN-slug/` tree, a pinned `.myclickup.toml` — and whether the
consumer has it. Verdict: **generic** (every repo), **conditional on X**, or **local to
me**. Evidence, not opinion.

**What should change.** A proposed edit to the skill text, quoted against the heading it
belongs under — not a description of a problem. A proposed diff is an order of magnitude
cheaper to triage, and it forces the reporter to have read the skill rather than guessed
at it.

**What the change is allowed to weigh — the risk class.** A proposed edit to a step in a
skill and a proposed edit to a rule that constrains agents are the same size on disk and
must not be the same thing to triage. The reporter classes the edit, and the class decides
the lane:

- **Mechanical** — a wrong path, a stale command, a step that cannot be followed as
  written. Applied directly, like any other correction.
- **Direction-setting** — anything touching a guardrail, an ADR, or the blueprint. Routes
  to the lane this repo already has for it: an ADR first, never a merge from a report
  alone, however small the diff.

The reporter's class is a claim, not a decision — a triager may reclassify upward, never
downward. This exists because the alternative is that the lane gets picked by whoever
reads the report and how large the diff looked, which is not a rule.

Then the cheap ones: install mode (plugin / user-scope / vendored container copy);
invocation and arguments as run; the step it broke at, quoted verbatim by heading;
once-versus-every-run; the workaround already applied locally; and **which artifact is
wrong** — the skill, the blueprint (`reference/`), a template, or an ADR. Without that
last field every report is filed against the skill that surfaced the problem and the
blueprint never improves.

The rule the whole schema serves, stated in the skill itself: **a report must be
actionable with no reply, and no response is guaranteed** — the consumer is expected to
unblock itself locally regardless. Making the channel one-way by construction is what
removes the ping-pong.

Two fields that cost nothing and are worth more than they look:

- **Negative space** — "I went looking for a skill for X and there was not one." Never
  collected by a bug-shaped form, and more useful than most bug reports.
- **A symptom slug picked from a short fixed list.** Three reports of one friction are a
  signal; one is an anecdote. Free-text reports all read as unique and can never be
  grouped.

### 3. Skill-side surface — one home, two lines each

Author the envelope once as a sixth skill (`report-skill-feedback`) that owns the schema.
Each existing skill gets two lines pointing at it — *if these instructions were wrong or
did not fit this repo, file it before you work around it* — and nothing else. Pasting the
block into five skills would put the schema in five places, which the one-home-per-role
rule (work/archive/0011, WP7) exists to prevent.

Trigger point matters as much as the text: the best information exists **at the moment
the agent deviates from the skill**, not at the end of the thread. Put the pointer there,
and add a single sweep question to `/wrap-up` ("did any skill mislead this thread?") as
the safety net.

### 4. The guardrails that decide whether it works at all

- **The gate must sit outside what a report can change.** Our guardrails live *inside* the
  skills — what may cross to the board and what may not, never push without approval, the
  leak rule below, the read-only rule above. A channel that lets a consuming agent propose
  edits to the skill text therefore lets it propose edits to its own constraints, and a
  gate inside the material it is gating does not hold. This is what the risk class in §2
  is for, and it is the reason the class is mandatory rather than advisory: the
  enforcement lane (an ADR, a human) has to be reachable without reading the diff first.
- **Ban the silent local edit.** The default agent behaviour is to fix the vendored copy
  and move on — after which the copy has diverged, nothing is filed, and the sync checks
  accumulate noise. Consumer copies are read-only; a deviation must be recorded in the
  consumer repo *and* filed upstream. Divergence becomes visible instead of silent.
- **Close the loop where consumers can see it.** Feedback with no observable outcome stops
  arriving after roughly three reports. The surface already exists: when a report becomes
  a change, its `CHANGELOG.md` entry names the report it came from. One line, and it is
  the difference between a channel and a suggestion box.
- **A leak rule.** A report copies context out of a possibly-private consumer repo into
  this one. `.cache/` is already gitignored here specifically because it can carry
  customer-identifying names; the envelope needs the same discipline stated explicitly —
  minimum excerpt, no client names, no identifying paths.

### 5. Replay-test the schema before shipping it

Take incidents that actually happened and write them as envelopes retrospectively: the
`variants/` directory that `sync-plugin` would still carry into the payload
(`work/0003-skills-beyond-this-repo/proposal.md` §3), the plugin-payload links that
escaped and were fixed twice, and the vendored wheel whose version string did not identify
its contents (myclickup work/0011 §4). If the envelope would not have made them
actionable, the schema is wrong. An hour of work, and the cheapest way to avoid finding
the flaw across twenty misfiled reports.

## A second worked instance — the `numerai` notice-paths report (added 2026-08-20)

A consuming agent in the `numerai` repo (same `nranthony` profile) reported 2026-08-19,
against the blueprint's environment-notice section: the three content rules never
constrain *where the human step happens*, so a notice satisfies rule 2 by naming a
host-side mechanism — and a live notice did exactly that, citing `scripts/with-egress.sh`,
a host-only script in the sandbox tool's own repo that resolves to nothing in any
consumer. It proposed a fourth content rule and a read-only verification pass through the
managed markers. Triaged and applied 2026-08-20 (blueprint, `apply-conventions` step 1,
CHANGELOG under 0.5.0); the dead reference itself sits inside a block no container may
edit, so that half is the tracked handoff named in the header.

Run as the §5 replay test, on live traffic:

- **The envelope holds it.** The report named the wrong artifact correctly (the
  blueprint, not the skill that surfaced it), quoted the step it broke at by heading,
  and proposed diffs rather than descriptions — the three expensive fields, all present
  unprompted. It lacked the version stamp, the generic/conditional/local verdict, and a
  risk class; triage supplied all three without a round trip, but only because the
  triager could read the blueprint's history. The schema would have made that free.
- **§2's risk class is too coarse, and this report proves it.** As drafted,
  "direction-setting — anything touching a guardrail, an ADR, or the blueprint" routes
  *every* blueprint edit to the ADR-first lane, including this one: a content
  clarification that follows from decisions already made, changing no decision.
  Direction-setting should mean *changing what the blueprint or a guardrail decides*,
  not *editing the file it lives in*. Whoever implements §2 redraws the line by effect,
  not by artifact — the reclassify-upward-only rule already covers the abuse case.
- **One rewording survived triage rather than the report's text.** The proposed rule
  ("every path a notice names must resolve inside the repo the notice ships in") was
  too strong — it would ban the most useful content in our own notice: absolute
  in-sandbox paths (`/usr/lib/wsl/lib/nvidia-smi`), service hostnames
  (`postgres:5432`). The rule that shipped tests frame of reference — resolve where
  the reading agent stands — which keeps the report's failing example failing and the
  legitimate content legal. Worth remembering for the skill text: a proposed diff is
  the cheapest thing to triage *and* still a claim, not a patch to apply blind.

## Non-goals

- Any automatic mutation of a consumer repo, or of this one, on receipt of a report — the
  reference-not-automation decision ([ADR-0001](../../docs/adr/0001-reference-not-automation.md))
  holds; a human or an agent triages by hand.
- A reply channel, a ticket state machine, or SLAs. One-way by design (§2).
- Telemetry or anything that reports without the agent deciding to.
- A second tracker. A report that survives triage becomes a `work/` item, which is where
  the board sync already reaches ([ADR-0008](../../docs/adr/0008-clickup-work-sync.md)).

## Prior art — what this converges with, and what it deliberately does not take

Assessed 2026-08-18 against a survey of vendor-documented practice (OpenAI's
self-evolving-agents cookbook, Karpathy's `autoresearch`, Anthropic's memory/subagent/hook
primitives, the OpenTelemetry GenAI semantic conventions, and trace-to-eval promotion in
the observability tools). **The survey's citations are unverified from inside the sandbox**
— no network — so what follows judges the ideas, not their attribution. Anything from here
that ends up in an ADR needs the sources checked first.

**Where it converges, independently.** The dominant shape is *emit → score → propose a
change → gate the change*, and the gating step everyone lands on is a proposal record with
a human signer: the agent submits a minimal diff, nothing ships until a human confirms,
and agents accumulate patterns without rewriting their own instructions. That is §2 and
the reference-not-automation decision
([ADR-0001](../../docs/adr/0001-reference-not-automation.md)), arrived at separately. Their
field list — artifact path, diff, evidence, scores, risk class — is also where §2's risk
class came from; we had the first three and were missing the last. Worth recording that
the human-in-the-loop stance is not caution: it is where people running these loops at
volume also ended up. Likewise the absence of any standard protocol or endpoint for this,
and the observation that file conventions won over database schemas because git already is
the versioning and rollback layer — that is the argument for §1 and against both rejected
alternatives.

**Where the analogy breaks, and why the telemetry tier does not apply.** Those pipelines
score **output quality**: a grader marks a result low and something revises the
instructions. Our failure mode is invisible to that. An agent reads "run the repo's checks
(`just check`)", finds no `justfile`, works around it, and produces perfectly good
output — every grader passes, every trace shows success, and the fact we want (*the
instruction assumed a repo shape that was not there*) is destroyed at the moment it
exists. No amount of tracing recovers it, because nothing anomalous was traced. This
channel is therefore not a low-budget substitute for an observability stack; it targets a
signal that stack structurally cannot see. The agent's own judgement at the point of
deviation is the emitter, and there is no substitute for it.

**What is worth striving towards.** The telemetry tier (OpenTelemetry GenAI attributes, a
trace store, an ingest endpoint) is the right destination if this ever serves more than one
user, and wrong to build now: it needs network the sandbox denies, a service to run, and a
report volume we are nowhere near. The cheap thing available today is to leave the seam —
the symptom slug in §2 is the same instinct as a stable operation-name attribute, so naming
the envelope's fields with an eye on where they would map makes a later adoption a rename
rather than a redesign. Similarly, promoting production traces into a curated evaluation
set has a no-infrastructure analogue we already have: the replay test in §5 is a held-out
set of real incidents.

**What we deliberately reject, on their evidence.** Self-rewriting instructions and
metaprompt loops are out under ADR-0001, and the survey supplies the argument for us: the
static-metaprompt version **overfit to its graders**. A skill that rewrites itself to
satisfy whatever signal it is scored on is the failure mode, not the goal. The durable
lesson underneath — do not tune against the same signal you evaluate on — is what §5 is
already doing, and anything more is premature at our volume. Also rejected: the emerging
convention of an `AGENTS.md` that agents append learnings to indefinitely. Our rule is
stronger on purpose — nothing durable lives only in a work item; it distils to an ADR —
and adopting the notebook pattern would be a downgrade wearing the clothes of a standard.

## Exit rule

This item closes when the channel is built and a consumer can file a report — or when the
question is resolved the other way and the item is rejected.

**The ADR is written at implementation time, not now** (decided 2026-08-18). This is
direction-setting by the repo's own test — a new skill, a new payload artifact, and a rule
binding consumer behaviour — so it does need one; but writing it against a Draft proposal
would pin decisions the build will change, and ADRs here are append-only. So: whoever
implements §1–§3 writes the ADR as part of that work, **before the skill ships**, not
after. Its load-bearing content is the risk-class split and the gate-outside-the-substrate
rule (§4), since those bind consumers rather than describing our own plumbing. Open
question 5 gates it: nothing from the prior-art section may be cited until those sources
are checked.

The proposal's status line then becomes `Accepted → ADR-NNNN` and the folder archives.

## Open questions

1. **Overlap with the on-hold distribution item.** `work/0003-skills-beyond-this-repo`
   already owns "surfaces outside the checkout". A feedback path has to work on every
   surface that item enumerates, and §3 there (the claude.ai variant) is the one where the
   copy-to-inbox transport is impossible. Fold this in as a section of 0003, or keep it
   separate and cross-reference?
2. **Where does a consumer's tracked original live** when the consumer is not on these
   conventions and has no `work/` tree? A `feedback/` folder is the fallback in §1, but it
   is asserted, not decided.
3. **Does the `VERSION` sidecar belong to this item or to the channel?** Stamping is
   independently useful — it is also the missing half of "which version am I running" for
   every consumer — and might ship on its own regardless of what happens to the rest.
4. **Grouping mechanics.** The symptom slug (§2) implies a fixed list that has to be
   maintained and that reporters can actually match against. Who owns that list, and what
   happens when nothing fits?
5. **The prior-art sources are unverified.** They were assessed from a survey, from inside
   a sandbox with no network. Before any of it is cited in an ADR, someone with egress
   confirms the specifics — the overfitting finding and the proposal-record-with-signer
   pattern are the two doing real argumentative work here, so they are the two that matter.

## Alternatives

- **Do nothing; rely on the owner noticing.** Works at one user and one machine, which is
  where the repo is today. It stops working the moment a skill runs somewhere the owner is
  not watching — which is already true of the container.
- **A tracked `feedback/` directory here instead of the gitignored doorbell.** Reports
  survive and are diffable, but the folder becomes a second work-tracking surface with no
  lifecycle, competing with `work/`. Rejected in §1.
- **An issue tracker (ClickUp) as the inbound surface.** It is the natural home for triage
  state, but a consuming agent cannot always reach it: it needs the client on PATH and a
  pinned workspace, neither of which a foreign consumer has. Files travel where API calls
  do not. A report can still be promoted onto the board once it becomes a work item.
- **A reply channel and a real conversation.** Higher fidelity per report, and precisely
  the cost this proposal exists to avoid. The one-way constraint is the design, not a
  limitation of it.
