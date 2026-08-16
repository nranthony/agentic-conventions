# Proposal: Gloss shorthand, not just identifiers

- Status: Draft — decision-ready. Reviewed with the owner 2026-08-16; the four questions
  the first draft left open are resolved and folded in (see *Resolved in review*).
- Author: nanthony (owner), carrying findings from the agent in `myclickup`; drafted by
  the agent in `agentic-conventions`
- Opened: 2026-08-16
- Extends: the gloss-before-cite decision (ADR-0010, Accepted 2026-08-12). That record is
  append-only, so this lands as a **new** record building on it, never as an edit to it.
- Number note: the brief proposed `0014`; `work/0014-wrap-up-generality/` was opened the
  same day, so this item takes the next free number across active and archived items —
  `0015`, re-verified 2026-08-16.

## Summary

The house rule says: when writing for a human, state the substance in plain language and
put the identifier in parentheses after — "the reference-not-automation decision
(ADR-0001)", never "per ADR-0001". It covers **manufactured identifiers with a canonical
home**: decision numbers, work-item slugs, section numbers, ticket IDs.

It says nothing about the other half of the problem: **project-internal shorthand coined
in flight** — plan-item letters, task-table codes, question numbers, codenames, acronyms.
Nothing anywhere in this repo addresses it. This proposes extending the same habit to
cover it, landing on the same two instruction surfaces the original did, with the same
edges (human-facing only, repetition decay, write-once artifacts gloss on first mention).

The two rules **merge into one bullet** on those surfaces even though the records stay
separate: they are one habit with two triggers, not two habits.

## Motivation

Recent exchanges across this ecosystem produced sentences like:

- "R3 shipped"
- "B0–B7 are theirs"
- "T5 is open"
- "E13 blocks the mapping"

Each was clear to the agent that coined it and opaque to the human reading cold — and to
the next agent in a fresh session, which is the case the original rule did not have to
worry about.

**Shorthand is a worse offender than the identifiers already covered, not a milder one.**
The original argument was that a bare "ADR-0005" costs the agent a grep and costs the
human a context switch. Shorthand breaks even that asymmetry: "R3" often has no canonical
home at all. It resolves only against *which* plan, *whose* table, *which* exchange coined
it. A fresh agent grepping `R3` gets nothing useful; the human gets the same context
switch plus an ambiguity the identifier version never had. The rule that already exists is
therefore under-scoped relative to its own reasoning, not over-scoped.

The gap is also structural rather than incidental: the existing rule enumerates covered
identifier *kinds* (decision numbers, work-item slugs, section numbers, ticket IDs).
Shorthand is not an omitted item on that list — it is a category the list was never
written to admit, so no amount of reading the current record charitably closes it.

## Proposal

**1. Project-internal shorthand always glosses.** Plan-item letters, task-table codes,
question numbers, codenames: name the thing, then cite the code.

> "the task-move command (R3 in the plan) shipped" — not "R3 shipped"
> "the bootstrap steps (B0–B7) are theirs" — not "B0–B7 are theirs"

**2. The obligation is to convey what the thing *is* — which distinguishes a name from a
code.** A name plus its category word already discharges it: "the `nranthony` profile"
tells the reader what kind of thing it is and is unique enough to look up. A code plus its
category word does not: "the R3 plan item" says where to look and nothing about what it
is, so only "the task-move command (R3)" pays the debt. This is why the repo's stable
internal vocabulary — the channel, member repos, the deployment tier — costs at most a
category word: it was named in English, so the name is the gloss.

**3. Acronyms expand on first use when the reader may not hold them.** Audience judgment,
the same spirit as the existing rule's decay clause — not a mechanical always-expand.

**4. Genuine technical vocabulary is not the target.** "Wheel", "manifest", "rebase",
"lockfile" are the plain terms; there is nothing to gloss them *into*. Three tests, in the
order they are cheapest to apply:

- **Provenance (author-side, use first).** Did this project coin it? If yes, gloss. You
  already know the answer without simulating a reader, and it settles every observed
  failure instantly.
- **Findability (tiebreak).** Could the reader resolve it without opening a document
  someone here wrote? A search result or a man page means vocabulary.
- **Decodability (tiebreak).** Could a competent outsider reading cold get the right
  answer? Most correct, slowest, reserved for the genuinely unclear case.

**When still unsure, gloss.** The error costs are lopsided: over-glossing costs a few
words and reads mildly explanatory, while under-glossing costs the reader the exact
failure the rule exists to prevent. The default follows from the asymmetry, and it lets a
writer decline the boundary question rather than having to answer it.

**5. Enumerations gloss the set, not each member.** "The seven bootstrap steps (B0–B7)"
discharges the obligation for the whole range; walking a table row by row afterwards does
not re-gloss every code. This is where a naive reading of rule 1 would be most expensive,
so it is stated rather than left to be inferred.

**6. Define at coinage.** Shorthand introduced in a numbered list or table within the same
response is glossed *by that list*; prose referring back to it in that response may use
the bare code. A table row keyed `R3 | move a task between lists` is itself the gloss.

**7. Same edges as the existing rule, inherited verbatim.**

- *Human-facing surfaces only.* Assistant responses, commit and PR text, docs a human
  reads — proposals, plans and handoffs included, since the owner is their primary reader.
  Agent-internal cross-references stay code-first.
- *Repetition decays at agent discretion*, same discretionary window.
- *Write-once artifacts gloss on first mention, with no decay.*

**8. Placement follows the existing rule's own precedent, and merges with it.**

- A new decision record in `docs/adr/`, taking the next free number when written, citing
  the 2026-08-12 record as the thing it extends. Its Context states plainly that the
  instruction surfaces carry one merged rule while the records stay separate — so the
  split is legible from the record side, where someone is actually reading for history.
- **One widened bullet** in `AGENTS.md`, replacing the current one at `AGENTS.md:76-79`
  rather than sitting beside it:

  ```
  - **Gloss before you cite.** When writing for a human, name the thing in plain language
    first and put the code in parentheses after it — an identifier ("the
    reference-not-automation decision (ADR-0001)", never a bare "per ADR-0001") or project
    shorthand ("the task-move command (R3 in the plan) shipped", never "R3 shipped").
    Ordinary technical vocabulary is already plain. Repeated mentions of the same thing
    within an exchange may drop the gloss (ADR-0010, ADR-00NN).
  ```

- **One widened line** in `templates/AGENTS.md` Golden rules, replacing
  `templates/AGENTS.md:57-59`, which the plugin payload copy carries byte-identical to
  every stamped repo:

  ```
  - Gloss before you cite: writing for a human, say what a thing is in plain
    language and put its code in parentheses after — "the no-scaffolder decision
    (ADR-0001)", not "per ADR-0001"; "the task-move item (R3)", not "R3".
    Covers project shorthand, not ordinary technical terms. Repeat mentions may
    drop the gloss.
  ```

  If that line must shrink, cut the third sentence rather than an example — the two
  examples side by side already imply the scope, and the record carries the boundary
  argument for anyone who needs it.

- **Not** `reference/agentic_native_repo_scaffold.md` — a writing habit is not repository
  structure — and **not** a skill: a skill is an invoked procedure, and this must apply to
  every sentence written, which is what an instruction file is for.

**9. It is advice, not enforcement, for the same reason as before.** A correctly glossed
sentence still contains the code, so no grep separates compliant text from bare text.
Shorthand is in fact *less* lintable than `ADR-\d+`: there is no pattern to match on,
because the whole point is that the codes are coined ad hoc.

## Consequences to expect

- One widened line reaching every stamped repo — five lines against three, which makes it
  the longest entry in a three-entry Golden rules section. Accepted: it is one of this
  house's signature habits, and the negative half of each example ("not `per ADR-0001`")
  is what does the teaching.
- Denser prose in exactly the places already densest — plan walkthroughs and status
  summaries. Rules 5 and 6 exist to keep that cost bounded.
- A repo that coins no shorthand never triggers the new half.
- Unverifiable, like its parent. The only feedback loop is a human saying "what is R3?".

## Resolved in review (2026-08-16)

The first draft left four questions open. All four are settled; the reasoning is recorded
here and the positions are folded into the Proposal above.

**1. One bullet or two → merge.** Two adjacent bullets both opening with "Gloss" invite an
agent to read the first, recognise the pattern, and skip the second as a restatement —
dropping the half that is newer and less intuitive. Scope, decay and the write-once
carve-out are identical between them, so two bullets pay for the shared edges twice in a
file where every line competes for attention. The one wrinkle — a merged bullet citing two
records sends a follower to a record silent on shorthand — is handled from the record
side, per rule 8.

**2. The vocabulary boundary → judgment call, provenance-first, with a default.** An
enumerated allow-list was rejected on a stronger ground than rot: it would live in
`templates/AGENTS.md` and ship to repos whose vocabulary has nothing to do with this
one's, so it was never alive outside this repo to begin with. What makes the judgment call
cheap is ordering the tests by cost and adding the when-unsure default (rule 4).

**3. A carve-out for stable sandbox-tier vocabulary → dissolved, not granted.** The
recurring cross-repo terms are already glosses: "the deployment tier", "the channel",
"member repos" were named in English. The rule bites on *codes*, and the name/code
distinction (rule 2) discharges stable named vocabulary for the price of a category word.
A second exemption route would need maintaining and would invite litigation over whether a
given term is "stable enough" — a question with no answer and no upside.

**4. A worked example in the template line → yes, in contrast form.** The objection that a
stamped repo has no `R3` applies equally to the existing example: a stamped repo's ADR-0001
is almost certainly not the no-scaffolder decision. The example was never demonstrating
content, it demonstrates shape — and shape matters more here, because "gloss identifiers"
is nearly self-executing (you can see `ADR-0001` in your own sentence) while recognising
that what you just typed *was* shorthand is the whole difficulty.

Nothing blocking remains. The next step is the owner's acceptance.

## Follow-through if accepted

A template change carries the standing obligation: `just sync-plugin`, then `just check`
(check-plugin-sync, check-plugin-links, check-versions, check-vendored, validate), a
CHANGELOG entry, `version` bumped in **both** `plugins/myconv/.claude-plugin/plugin.json`
and `.claude-plugin/marketplace.json`, then republish through the depot channel
(`just publish agentic-conventions "..."` from the channel root).

**Exit rule:** proposal accepted → new decision record written → both instruction surfaces
updated → plugin regenerated, version bumped, republished → item archived.

## Sequencing

Not urgent. The work-item status vocabulary arriving separately (`inbox/`, handed over
from the `myclickup` side 2026-08-16, gated on a research document still to come) touches
the same surfaces — `templates/AGENTS.md`, a plugin version bump, a channel republish. Two
observations:

- **No conflict in substance.** That item *defines* a vocabulary (`Draft`, `In execution`,
  `Blocked — <reason>`); defined terms with a written home are the opposite of the ad-hoc
  shorthand this rule targets. Rule 4 excludes them by construction, and rule 2 would
  charge them at most a category word.
- **Batch the republish** if both land close together. Two template edits, one
  `sync-plugin`, one version bump, one publish line — rather than two of each.

## Alternatives

- **Do nothing; the existing rule's spirit covers it.** Rejected: it does not. The record
  enumerates covered identifier kinds and shorthand is not among them, so an agent
  following it literally — the intended mode — leaves "R3 shipped" untouched. The observed
  failures are the evidence.
- **Amend the 2026-08-12 record instead of adding one.** Rejected: decision records here
  are append-only and supersede rather than rewrite. The original also remains correct on
  its own terms; this widens scope rather than replacing a judgment.
- **Two bullets on the instruction surfaces** — rejected under *Resolved* 1.
- **An enumerated list of exempt technical terms** — rejected under *Resolved* 2.
- **A second exemption route for documented, stable vocabulary** — rejected under
  *Resolved* 3.
- **Put it in the blueprint as a named writing pattern.** Rejected on the same grounds the
  original was: the blueprint argues repository structure, and the template is already the
  delivery vehicle to every consumer.
- **Ship it as a skill.** Rejected under rule 8: a skill is an invoked procedure; this is a
  standing habit.
- **Enforce mechanically.** Rejected: strictly harder than the already-rejected version.
  Ad-hoc codes have no matchable pattern, and glossed text still contains the code.
- **Ban project shorthand outright in human-facing writing.** Rejected: the codes carry
  real value in tables and plans, where they are the compact key to a row. The problem is
  a bare code in *prose*, not the code's existence.
