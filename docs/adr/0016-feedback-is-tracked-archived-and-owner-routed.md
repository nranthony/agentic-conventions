# ADR-0016: Feedback is tracked, archived, and routed to the repo that owns the skill

- Status: **Accepted**
- Date: 2026-08-25
- Deciders: nranthony + agent
- Amends: ADR-0013 (skill-feedback channel), which stays Accepted. This record replaces
  its §1 transport and the `inbox/`-is-ephemeral consequence; every other decision in
  0013 — the one-way rule, the envelope, risk class by effect, the three roles, the
  read-only consumer copy, the leak rule — stands unchanged.
- Distilled from: four findings from the channel's first full day of live traffic
  (2026-08-25), three of them surfaced by triaging reports the channel itself delivered.

## Context

ADR-0013 shipped a one-way feedback channel and it worked — three reports arrived, all
three were actionable, and two produced signed decisions the same day (ADR-0014,
myclickup ADR-0016). What that day also produced was four defects in the channel itself,
which only became visible once real traffic ran through it.

**1. Routing assumes a single owner.** §1 says the reporting agent "copies it to *this*
repo's `inbox/`", and §4 defines triage as a session in "*this* repo". Both are written
destination-singular, because at the time the five `myconv` skills were the whole
population. They are not: `myclickup` ships its own agent skill as half a wheel+skill pair,
recorded in the channel manifest as `kind = "wheel+skill"`. A report about that skill
routed to this repo lands where nobody can act on it. This was filed as a report through
the channel, which is the cleanest possible demonstration that the channel works.

**2. Retention destroys the evidence the design asks for.** The envelope requires a symptom
slug so repeats can be grouped — *"three reports of one friction are a signal, one is an
anecdote"* — and §4 has triage "group repeats". But §1 deletes the doorbell on action, the
Consequences accept that "an unpromoted report vanishes with the checkout", and no archive
exists. So report #1 is gone by the time #3 arrives and the threshold can never be
evaluated. The same holds for *"recurring none-fits are how the list grows"*.

This is not theoretical. On day one, **two independent reporters made the same
`Install mode` error** (see 4). That is two-thirds of the stated threshold, visible only
because both landed in one session with both triages reporting to one place. Under 0013's
retention it would have been invisible.

**3. `inbox/` does two jobs with opposite retention needs.** `AGENTS.md` defines it as
"ephemeral paste-in material" *and* the feedback doorbell. Ephemeral paste should be
gitignored and disposable; feedback should be kept. Today that directory holds a 25KB
paste-in, two handoff transfers, and one feedback report — and one rule cannot be right for
both.

**4. The `Install mode` enum is mis-picked in practice.** Both of day one's external reports
described a skill seeded into a container's agent home by the host image — the envelope's
"vendored container copy" — and one filed it as `plugin`, the other as `user-scope`. Neither
lost a round trip, because both self-described in a parenthetical. But the field exists to
tell triage *which text to diff against*, and getting it wrong is exactly the guesswork the
`VERSION` sidecar was added to end.

## Decision

1. **A report goes to the repo that *owns* the skill**, which is the repo it ships *from* —
   not the repo it ran in, and not this repo by default. The `myconv` skills belong here; a
   tool's own vendored skill belongs to that tool's repo. Where a channel is in play, its
   `manifest.toml` names the `source_repo` for every shipped artifact: **read it rather than
   guessing**. If the owning repo has no `feedback/`, say so in the report and fall back to
   ADR-0013 §1's human-ferried step.

2. **The destination is `feedback/`, and it is tracked.** This replaces `inbox/` for
   feedback traffic:

   ```
   feedback/            inbound reports awaiting triage
   feedback/archive/    triaged, with the disposition recorded
   feedback/sent/       copies this repo filed elsewhere (only where a repo also sends)
   ```

   ADR-0013 rejected "a tracked `feedback/` directory" as "a second work-tracking surface
   with no lifecycle". That rejection was right about a *queue* and wrong about a *record*:
   what is tracked here has one transition (triaged → archived), no status, and no exit
   rule. The work item, when a report earns one, still lives in `work/`.

3. **`inbox/` keeps its other job, unchanged and still gitignored**: ephemeral paste-in
   material and handoff doorbells. A handoff is not feedback — it is addressed traffic
   between two repos that already know about each other, and `/handoff` continues to route
   there. Renaming `inbox/` rather than splitting it would have started tracking the paste,
   which is the opposite of what it is for.

4. **Triaged reports are archived, never deleted.** This is ADR-0012's archive-never-delete
   rule applied to a second surface, for the same reason: an archived record is explicitly
   historical, and a deleted one is indistinguishable from one that never arrived. A report
   that triage *rejects* is archived too — those are the ones recurrence-counting most needs,
   and the ones a CHANGELOG entry can never capture.

5. **`feedback/README.md` is the ledger**: the lifecycle, plus one line per report — date,
   from-repo, skill, slug, risk class, disposition. It exists because disposition is not
   recoverable from the report file, and because grouping by slug needs something greppable
   that outlives the individual reports. One file, no new tooling.

6. **The `Install mode` field gains a decision rule** in the envelope: *how did the text get
   there?* Installed from a marketplace → `plugin`. Copied into the agent home by a person or
   a repo → `user-scope`. **Baked into a container image by the host, seeded at
   `~/.claude/skills/<name>/` → `vendored container copy`** — that last is the case both day-one
   reports hit, and the one whose answer changes which text triage diffs against.

7. **The sender's copy is unchanged and still authoritative.** ADR-0013 §1's "the tracked
   original lives in the sender's repo" holds. What changes is that the receiver now keeps
   one too, so recurrence is countable from the owner's side without reading N consumer
   repos.

## Consequences

- **The threshold in the envelope becomes real.** "Three reports of one friction" and
  "recurring none-fits" can now be evaluated by grepping `feedback/archive/` and the ledger.
  Until today they were unfalsifiable claims in shipped text.
- **A rejected report leaves a trace**, which it never did before. Expect the archive to be
  more useful than the CHANGELOG for spotting patterns, since the CHANGELOG structurally
  only records reports that became changes.
- **Two directories where there was one**, and a reporter now has to determine ownership
  before filing. The manifest makes that a lookup rather than a judgment, and the fallback
  is the existing human-ferried step.
- **`inbox/` shrinks to what it was always best at** and stops being a place things are lost.
- **Consumer-visible**: the `report-skill-feedback` envelope and its routing step both change,
  so this ships in the same release as ADR-0014 and ADR-0015.
- Nothing here weakens the one-way rule. A tracked archive is not a reply channel, and no
  response is still guaranteed.

## Alternatives considered

- **Rename `inbox/` to `feedback/`.** The obvious move, and wrong: `inbox/` holds disposable
  paste-in that would become tracked overnight. Splitting costs one directory and no
  migration to speak of — on the day it was decided, only two files of seven needed to move.
- **A ledger only, with no archived reports.** Cheaper, and it loses the report text — which
  is what a later reader needs to judge whether two slugs are really the same friction.
- **Keep deleting doorbells and count recurrence from senders' repos.** The corpus exists
  there but is scattered across N repos with no index, several of them private and some
  unreachable from any container. Unqueryable in practice.
- **One `feedback/` shared by inbound and outbound.** Rejected: "what is in `feedback/` needs
  triage" stops being true the moment sent copies live there too. `sent/` costs one line.
- **Route by where the skill ran rather than where it ships from.** That is the current
  broken behaviour restated — it puts reports where the text cannot be edited.
