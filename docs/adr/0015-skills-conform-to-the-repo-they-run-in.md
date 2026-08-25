# ADR-0015: A skill states what it does, not what a repo must contain

- Status: **Proposed** (flip to Accepted on sign-off)
- Date: 2026-08-25
- Deciders: nranthony + agent
- Generalises: ADR-0014, which is this rule's first application (the content axis)
- Distilled from: `work/0014-wrap-up-generality` (opened host-side 2026-08-16, reviewed
  here 2026-08-18) and `work/0018-clickup-pull-conformance` (opened 2026-08-18 from
  consumer feedback), which independently reached the same conclusion about two
  different skills.

## Context

The shared skills run in repos their author did not shape and cannot see. Each one
therefore has to answer a question at every step: *what does this repo actually have?*
Two independent investigations found the same wrong answer being given, in two skills,
by two different mechanisms.

**`/myconv:wrap-up`** (work/0014, evidence from a real run on `windows-ai-sandbox`):
discovery is name-based, and §0's "skip absent pieces silently" cannot distinguish a tier
that is **absent** from one that is **present under a different name**. The skill looked
for `.claude/skills/`, that repo keeps agent guides in `.agents/skills/`, and one of the
skill's own eleven sections silently did not run. The same run missed two of the three
documents that repo's `AGENTS.md` requires updating. The skill has the bug it exists to
help you find.

**`/myconv:clickup-pull`** (work/0018, reported by a consumer two days later): it requires
a pinned `[statuses]` table, hard-codes `proposal.md` where the lifecycle allows
`spec.md`, and asserts a front-matter layout — while, one sentence away, telling the agent
to use "the repo's own proposal template headings". It defers for headings and asserts
everything else. In the reporting repo the missing `[statuses]` pin was a *documented
decision* — that repo tracks work in `work/`, not on a board — so a deliberate choice read
to the skill as an error.

A third instance, in a check rather than a skill: this repo's own `check-vendored` printed
`[SKIP]` for days while `just check` closed with "all checks passed". Already fixed, and
already recorded in the justfile as *"a skip is not a pass; say so where it is read"* —
which is the same rule arrived at independently, from a third direction.

Three instances, three mechanisms, one property. Left unrecorded, each is patched in its
own skill in its own words, and two skills that are supposed to share a posture drift
apart. That drift is the thing this record exists to prevent — not any one of the defects,
which are being fixed anyway.

**ADR-0014 has already applied this rule to one axis.** It decided that a repo's rules
about what may enter a tracked file beat a skill's instruction to write it. That is this
principle on the *content* axis, signed a week before the general form. Recording the
general form now, rather than after a third application, is the whole point.

## Decision

**A skill states what it does when a repo has a thing, and what it says when it does not.
It never states what a repo must contain.**

Four rules follow, and they are the testable form:

1. **Absence is a state, not an error.** A repo that lacks an optional piece is not
   misconfigured. The skill proceeds where it can, on a stated basis, and says what it
   assumed. It stops only where proceeding would be unsafe or would silently produce a
   wrong result — and then it says which piece is missing and why that one is fatal.

2. **There is a third state, and it must be printed: *could not locate*.** "Present",
   "absent" and "present under a name I do not know" are three outcomes, not two. Name-based
   discovery collapses the third into the second, which is how a section silently does not
   run. Where a skill searches for something, an unsuccessful search **names the paths it
   checked** rather than passing quietly.

3. **A skip is not a pass; say so where it is read.** Adopted verbatim from this repo's own
   justfile, where it was learned the expensive way. A summary that reads as full coverage
   while a section stood down is worse than a failure, because nobody goes looking.

4. **Read the repo before asserting the repo.** Where a repo publishes its own shape — its
   `AGENTS.md`, its `work/README.md` lifecycle, its ADRs, its existing files — that is the
   authority, and it wins over the skill's default. Where it publishes nothing, the skill
   picks a default and **names it as a default**.

**Scope: every shared skill, not only the two that prompted this.** `apply-conventions`
already holds the posture for templates ("the repo wins"); `wrap-up` holds it for §0 and
loses it at §7; `clickup-pull` states it for headings and drops it everywhere else. The
rule is now the same in all of them.

**This does not license silent divergence.** Conforming to a repo means reading and
following what it declares, and saying so. It never means guessing, and it never means
patching the skill's own text locally — consumer copies stay read-only (ADR-0013 §6), and a
deviation is filed upstream.

## Consequences

- **`work/0014` and `work/0018` become applications, not decisions.** 0014's eight changes
  and 0018's Group A both implement this record; neither needs one of its own. 0018's
  Group B needs no decision at all — it is rule 3 applied in a second place.
- **ADR-0014 stays Accepted and unedited.** It is this rule on the content axis and now
  reads as the first application rather than as a competing statement. No supersession:
  0014 extends ADR-0008, this generalises 0014, and all three stand.
- **Skills get longer, and that is a real cost.** Stating the absent case, the located-under-
  another-name case and the default-taken case is more text than asserting a shape. Both
  work items already carry line budgets for exactly this reason, and the budgets should be
  set against live counts rather than remembered ones.
- **"Could not locate" output is new surface** a consumer will see. It should read as
  information, not as a warning to be silenced.
- Ships consumer-visible, batched — see the release note in `work/0018`'s Exit.

## Alternatives considered

- **Patch each skill in its own words.** What would happen by default. Rejected: two skills
  that share a posture would state it differently within one release, and the third
  instance would be reported by the next consumer rather than caught by the rule.
- **Fold the general rule into ADR-0014 by superseding it.** Rejected as disproportionate —
  superseding an accepted record a week old, to widen its scope, spends the append-only
  mechanism on something a second record does more cleanly. 0014's content-axis reasoning
  is also genuinely narrower and worth keeping legible on its own.
- **Record nothing; the work items carry it.** Rejected: work items archive, and the
  argument would then live in two archived proposals that no future skill author reads.
  That is the failure `/wrap-up` §9 names — a durable fact whose only home is a place
  nobody searches.
- **Make the repos conform to the skills instead** (mandate `[statuses]`, mandate
  `.claude/skills/`). Rejected on the reporting repo's own evidence: its missing pin was a
  documented decision, and a shared skill that only works in repos shaped like this one is
  not shared.
- **Enforce it with a linter over the skill texts.** Rejected for now: the property is
  semantic ("does this sentence assert a shape?"), and a check that cannot read intent would
  either pass everything or block ordinary prose. The two line budgets are the only
  mechanical control, and they are enough while there are five skills.
