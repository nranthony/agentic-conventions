# Proposal: an inbound feedback channel for the shared skills

- Status: Draft
- Author: nranthony + agent (Opus 5)
- Opened: 2026-08-18

## Summary

Give agents that *use* the shared skills a way to report back when a skill's
instructions were wrong, stale, or a bad fit for the repo they were running in — without
opening a conversation. One folder (the existing `inbox/` doorbell), one envelope
schema with a single home (a sixth skill), and a set of guardrails whose whole purpose is
that a report is actionable **on arrival, with no reply**. The design goal is not
"collect feedback"; it is "never round-trip".

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

## Non-goals

- Any automatic mutation of a consumer repo, or of this one, on receipt of a report — the
  reference-not-automation decision ([ADR-0001](../../docs/adr/0001-reference-not-automation.md))
  holds; a human or an agent triages by hand.
- A reply channel, a ticket state machine, or SLAs. One-way by design (§2).
- Telemetry or anything that reports without the agent deciding to.
- A second tracker. A report that survives triage becomes a `work/` item, which is where
  the board sync already reaches ([ADR-0008](../../docs/adr/0008-clickup-work-sync.md)).

## Open questions

1. **Does this need an ADR before it is built?** It is direction-setting by the repo's own
   test — a new skill, a new payload artifact, and a rule binding consumer behaviour. The
   likely answer is yes, and it should be written before §1–§3, not after.
2. **Overlap with the on-hold distribution item.** `work/0003-skills-beyond-this-repo`
   already owns "surfaces outside the checkout". A feedback path has to work on every
   surface that item enumerates, and §3 there (the claude.ai variant) is the one where the
   copy-to-inbox transport is impossible. Fold this in as a section of 0003, or keep it
   separate and cross-reference?
3. **Where does a consumer's tracked original live** when the consumer is not on these
   conventions and has no `work/` tree? A `feedback/` folder is the fallback in §1, but it
   is asserted, not decided.
4. **Does the `VERSION` sidecar belong to this item or to the channel?** Stamping is
   independently useful — it is also the missing half of "which version am I running" for
   every consumer — and might ship on its own regardless of what happens to the rest.
5. **Grouping mechanics.** The symptom slug (§2) implies a fixed list that has to be
   maintained and that reporters can actually match against. Who owns that list, and what
   happens when nothing fits?

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
