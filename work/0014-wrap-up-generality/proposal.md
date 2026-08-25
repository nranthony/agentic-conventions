# Proposal: wrap-up's coverage degrades silently on repos it did not shape

- Status: Draft
- Author: host-side agent in `windows-ai-sandbox` (deployment tier) + nanthony
- Opened: 2026-08-16, from evidence — a real `wrap-up --dry-run` on a repo that
  follows the tiers but never ran `apply-conventions`
- Scope: `plugins/myconv/skills/wrap-up/SKILL.md` only. No other skill is implicated.

## Summary

`wrap-up` v0.3.0 ran on `windows-ai-sandbox` at the end of a long multi-issue thread
and **found real staleness that the thread's own author had missed** — one corrected
fact left standing in three separate documents, two missing ADRs, and a work item past
its exit rule. It works, and the run was proportionate rather than ceremonial.

It also **silently skipped one of its own eleven sections** and missed two of the three
documents that repo's own rules require updating. None of that is a correctness bug —
every miss traces to one structural property: **discovery is name-based, and §0's
"skip absent pieces silently" cannot distinguish a tier that is absent from a tier
that is present under a different name.**

Eight changes proposed below, in value order. #2, #3 and #5 are the ones worth doing
even if the rest are rejected.

## Motivation

The evidence, all from a single run:

| What happened | Why |
|---|---|
| §7 never ran | It looks for `.claude/skills/`; that repo keeps agent guides in `.agents/skills/`. Silent skip. |
| Two of three required docs unchecked | That repo's `AGENTS.md` mandates updating `ARCHITECTURE.md` **and** `sandbox-hardening-package.md` for security-sensitive changes, plus `verify`/`audit`. wrap-up knows about `ARCHITECTURE.md` generically and nothing about the other clauses. |
| A corrected fact survived in three files | The thread fixed a stale command count in the settings file; the same count sat in `ARCHITECTURE.md`, `docs/permissions-model.md` and `sandbox-hardening-package.md`. No section sweeps for the old form of a fact just corrected. |
| A parked work item went unflagged | §6 covers done→archive and in-flight→reflect-reality. It has no case for a *parked* item whose premise was deleted underneath it. |
| Stale enumerations in the architecture doc | §3 says "map/boundaries, not implementation detail" — so a repo map listing one test suite but not another, and quoting a pass count stale by 11, is out of scope by wording. |

The §7 miss is worth dwelling on: **the skill has the bug it exists to help you find.**
That repo spent the same week fixing three separate monitors that collapsed
"never configured" and "moved away" into one silent output. §0 does exactly that with
tiers.

## Proposal

### 1. §7 — make skill discovery path-agnostic

Replace the hardcoded `.claude/skills/` with *"wherever this repo keeps agent-facing
skills or operational guides — locate them from the root `AGENTS.md` index rather than
a fixed path."*

Drop the frontmatter assumption with it. The guides in that repo are plain `.md` with
no frontmatter, indexed from `AGENTS.md`; the "description is the retrieval trigger"
check has nothing to bind to. Degrade to: *is the index entry still accurate, and does
the guide still describe reality?*

### 2. §0 — add the third state

The structural fix, and the one that makes the rest unnecessary next time:

> Before skipping a tier, check whether something plays its role under another name —
> grep the root `AGENTS.md` / index for a decision log, a work tier, a skills
> directory. **Never configured is a skip; present under a different name is a miss.**
> Report the mapping you inferred.

The phrasing is `windows-ai-sandbox`'s, learned expensively: a guessed fallback path
made a three-release payload drift print the same line as a machine that had never
configured anything.

### 3. §0 — print the detected tier map before §1

Follows from #2 and costs one table. §0 detects silently today, so the operator cannot
see what *will not* be checked. Emit tier → path found, or "not kept", up front.

That repo's rule for this exact failure class: **a skip is not a pass** — a summary
reporting only what passed reads as full coverage.

### 4. New section — the repo's own change gate

Many repos define required checks in `AGENTS.md` for sensitive files. Proposed section:

> **Does the repo define its own gate for the files this thread touched?** Repos often
> state one in `AGENTS.md` — required checks to run, docs that must be updated, a
> commit-message convention. Enumerate it and check each clause. This is the highest-
> yield section on any repo mature enough to have written one down, because those
> clauses name the specific docs a generic wrap-up cannot guess.

In the run above this would have caught all three stale documents.

### 5. New section — the corrected-fact sweep

Highest value per line of any change here:

> If this thread **corrected a fact that was written down** — a count, a version, a
> filename, a mechanism, a command inventory — grep the repo for the old form before
> finishing. A fact corrected in one file and left standing in three is worse than
> never correcting it: the stale copies now disagree with a source that looks
> authoritative.

Mechanical, cheap, and it generalises to every repo regardless of tier layout.

### 6. §3 — check enumerations, not only boundaries

§3's "not implementation detail" wording excludes exactly what rots. Add: *"including
any enumeration the map carries — file lists, counts, command inventories. Those rot
silently because they read as prose."*

### 7. §6 — a third case for parked work

§6 handles done and in-flight. Add:

> If **parked**, check its premises still hold. A parked plan referencing something
> this thread deleted is stale in a way its own Status line hides.

### 8. §9 — rank the write-back destinations, and name the anti-pattern

"Propose where it should land" is under-specified at the moment of use. Proposed
ranking: **ADR** (a decision) > **architecture doc** (structure) > **AGENTS.md** (a
standing rule) > **skill** (a procedure). And name the failure mode:

> A durable fact whose only home is a commit message is lost — commit messages are not
> what future agents search.

Two findings in that thread were headed exactly there.

## What is already right — do not change these

Recorded so a future edit does not "fix" them:

- **The trigger line.** "For complex, multi-issue threads only… skip it rather than
  manufacture busywork" is why running it felt proportionate. Keep the discouragement.
- **`--dry-run`.** Behaved exactly as documented — propose everything, mechanical fixes
  included. No ambiguity about what would have been touched.
- **§10's apply/propose split.** The right granularity. More automation would weaken
  "never auto-write anything direction-setting."
- **§0's "do not propose adding opt-in machinery."** Correct and load-bearing; it kept
  a `CHANGELOG.md` and a `.claude/skills/` from being reported as gaps.
- **§2's `templates/` exception.** Real work: that repo has two `AGENTS.md` under
  fixture/template trees that would otherwise read as missing-stub bugs. Worth
  *generalising* the wording from `templates/` to "any example, fixture, or
  test-corpus tree" — but the exception itself is right.

## Open questions

1. **Does #4 belong in `wrap-up`, or in `apply-conventions`?** Arguably the convention
   should be "your `AGENTS.md` declares its own gate in a findable shape," and wrap-up
   just reads it. That is a bigger change and would only help repos that adopt it —
   whereas the §4 wording above works on repos that already wrote a gate in prose.
2. **Is #5 a `wrap-up` section or its own skill?** A corrected-fact sweep is useful
   mid-thread too, not only at the end.
3. **Does #3's tier map belong in the final summary instead of before §1?** Up front
   sets expectations; at the end it is evidence. Possibly both.
4. Should the skill say outright that **it is not a substitute for the repo's own
   gates**? A clean wrap-up on that repo would still have shipped three stale docs.

## Alternatives

- **Leave it; tell adopters to run `apply-conventions` first.** Rejected: the skill's
  own §0 is explicitly built for repos that did not, and it degrades gracefully by
  design. The gap is that it degrades *silently*, which #2 and #3 fix directly.
- **Hardcode more known paths** (`.claude/skills/`, `.agents/skills/`, `skills/`).
  Rejected for the same reason a guessed fallback path was removed from the sandbox's
  vendor scripts: a longer list of guesses still collapses two states, and it will be
  wrong for the fourth repo.
- **Make wrap-up run the repo's test/verify commands.** Rejected — out of character for
  a skill that proposes rather than executes, and it would need a command allow-list.
  §4 only asks it to *enumerate and check* the gate, not run it.

## Provenance

Findings are from `wrap-up --dry-run` on `windows-ai-sandbox` @ `3dbc759`,
2026-08-16, at the end of a thread spanning a cache migration, a permission-model
correction, and Part B of the tools channel (myclickup work/0016). The run's own
output — 2 ADRs drafted, 4 doc corrections, 1 archive, 1 parked-plan note — is the
evidence that the skill works; this proposal is only about what it could not see.

---

## Review (2026-08-18, agentic-conventions side)

Reviewed here at the owner's request. The draft above is **unedited** — this section
is appended, so the sandbox-side author's text stays theirs.

### Verdict

**Accept all eight.** The diagnosis is right and the evidence is a real run, not a
reading. #2, #3 and #5 are correctly identified as the load-bearing ones. Three
wording changes and one scope correction below; nothing here rejects a proposal.

### Scope correction — the file named is the generated copy

The Scope line names `plugins/myconv/skills/wrap-up/SKILL.md`. That is the **payload**,
which `just sync-plugin` overwrites from the canonical source. Edits there are erased
on the next sync and `just check-plugin-sync` hard-fails both ways. The file to edit is
`.claude/skills/wrap-up/SKILL.md`. Not a flaw in the argument — the author works
host-side, where only the vendored copy is visible — but it would have cost a round
trip.

### The scope is wider than "no other skill is implicated"

The same failure appears in `/clickup-pull`, reported independently by a consumer two
days later and now open as **work/0018**. That skill requires a pinned status-role
table, hard-codes a filename the lifecycle does not require, and asserts a front-matter
layout — while, one sentence away, telling the agent to use "the repo's own proposal
template headings." Four instances of exactly the property #2 names: **it cannot tell a
tier that is absent from one that is present under another name, or under another
rule.**

That makes this a two-skill argument, and 0018 recommends the rationale distil into
**one** record covering both. Writing it twice is how two divergent rules appear in two
skills that are supposed to share a posture. Concretely, the principle to record is
#2's, generalised past discovery:

> A skill states what it does when a repo has a thing, and what it says when it does
> not. It does not state what a repo must contain.

Under that, 0018's Group A is application, not a second decision.

A third instance, for whether the principle is worth a record at all: this repo's own
`check-vendored` printed `[SKIP]` for days while `just check` closed with "all checks
passed" — the same collapse of "not configured" into "fine", in a check rather than a
skill. That one is already fixed and already recorded in the `justfile` as *a skip is
not a pass; say so where it is read*, which is #3 arrived at independently.

### Three wording changes

1. **#1 — keep a floor under "path-agnostic".** "Locate them from the root `AGENTS.md`
   index" assumes an index exists and is accurate. On a repo with neither, the section
   silently skips again — the bug being fixed. Add: if no index resolves them, say so
   and name the paths checked. An honest "could not locate" is the third state; a quiet
   skip is not.
2. **#4 — say the gate is enumerated, not run.** The Alternatives section already draws
   this line, but the proposed section text does not carry it, and a future reader edits
   the section, not the alternative. Put "enumerate and check each clause; do not run
   them" inside the quoted block.
3. **#5 — bound the sweep.** "Grep the repo for the old form" on a large repo with a
   stale version string returns the vendor tree and every lockfile. Scope it to
   documentation and instruction surfaces, and cap what it reports rather than listing
   every hit.

### The four open questions

1. **#4 in wrap-up or apply-conventions?** Both, in that order. Wrap-up reads gates
   written in prose today; `apply-conventions` can later encourage a findable shape.
   Doing only the second helps no existing repo, which is the population the skill
   exists for.
2. **#5 its own skill?** No — a second model-invoked skill widens the trigger-collision
   surface that `work/0012` exists to narrow, and its trigger ("a fact was corrected")
   is not sharp enough to fire reliably. It stays a section. The `work/0012` selection
   test agrees: a procedure earns a skill only if the agent should reach for it
   unprompted, it recurs, and its trigger is sharp.
3. **#3's tier map — up front or at the end?** Both, and they are different artifacts:
   up front it sets expectations, at the end it is evidence attached to the summary that
   would otherwise read as full coverage.
4. **Say outright it is not a substitute for the repo's gates?** Yes. One line, and the
   provenance run is the argument — a clean wrap-up there would still have shipped three
   stale documents.

### Cost, for sequencing

The skill is 127 lines. Eight additions plus two new sections want a **≤150-line
budget**, or the trigger line's own "skip it rather than manufacture busywork" starts
being contradicted by the skill's bulk.

Landing is consumer-visible: `just sync-plugin`, `just check`, CHANGELOG, a version bump
in both plugin manifests, republish, re-vendor host-side. **Batch with work/0018** — same
record, same release, one cycle instead of two.

### Sequencing note

#7 (parked work) should follow the work-item **status vocabulary** still pending in
`inbox/`: "parked" collides with the `Deferred — <reason>` form proposed there. Nothing
else in this item is blocked.

## Landed (2026-08-25) — #7 only

**#7 is in**, worded around the *state* rather than the label: "if it is neither active
nor finished — paused, waiting on something, held for a decision". This sidesteps the
sequencing note's blocker entirely. That note held #7 behind the work-item status
vocabulary still sitting in `inbox/`, because "parked" collides with the
`Deferred — <reason>` form proposed there. Describing the state means whichever
vocabulary lands later, the sentence stays correct — so the collision never has to be
resolved for this item to ship. **#7 is no longer blocked on anything.**

The section keeps the author's diagnosis intact: the status line reads as "deliberate,
nothing to do here", which is exactly why a review skips it, and a held plan whose
premise this thread deleted is stale in a way its own label hides.

Still outstanding here: **#1–#6 and #8**, plus the three wording changes and the scope
correction from the review above. The ≤150-line budget should be re-checked against the
live count, not the 127 recorded at review time — the file was already 136 before this
change.
