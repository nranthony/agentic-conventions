# Proposal: Gloss shorthand, not just identifiers

- Status: Draft
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

**2. Acronyms expand on first use when the reader may not hold them.** Audience judgment,
the same spirit as the existing rule's decay clause — not a mechanical always-expand.

**3. Genuine technical vocabulary is not the target.** "Wheel", "manifest", "rebase",
"lockfile" are the plain terms; there is nothing to gloss them *into*. The test is
**decodability without this project's context**: if a competent outsider reading the
sentence cold could look the term up and get the right answer, it is vocabulary. If the
term only resolves against a document, table, or conversation belonging to this project,
it is shorthand and it glosses.

**4. Enumerations gloss the set, not each member.** "The seven bootstrap steps (B0–B7)"
discharges the obligation for the whole range; walking a table row by row afterwards does
not re-gloss every code. This is where a naive reading of rule 1 would be most expensive,
so it is stated rather than left to be inferred.

**5. Define at coinage.** Shorthand introduced in a numbered list or table within the same
response is glossed *by that list*; prose referring back to it in that response may use
the bare code. A table row keyed `R3 | move a task between lists` is itself the gloss.

**6. Same edges as the existing rule, inherited verbatim.**

- *Human-facing surfaces only.* Assistant responses, commit and PR text, docs a human
  reads — proposals, plans and handoffs included, since the owner is their primary reader.
  Agent-internal cross-references stay code-first.
- *Repetition decays at agent discretion*, same discretionary window.
- *Write-once artifacts gloss on first mention, with no decay.*

**7. Placement follows the existing rule's own precedent.**

- A new decision record in `docs/adr/`, taking the next free number when written, citing
  the 2026-08-12 record as the thing it extends.
- A bullet in `AGENTS.md` beside the current one (`AGENTS.md:76-79`).
- A line in `templates/AGENTS.md` under Golden rules (`templates/AGENTS.md:57-59`), which
  the plugin payload copy carries byte-identical to every stamped repo.
- **Not** `reference/agentic_native_repo_scaffold.md` — a writing habit is not repository
  structure — and **not** a skill.

**8. It is advice, not enforcement, for the same reason as before.** A correctly glossed
sentence still contains the code, so no grep separates compliant text from bare text.
Shorthand is in fact *less* lintable than `ADR-\d+`: there is no pattern to match on,
because the whole point is that the codes are coined ad hoc.

## Consequences to expect

- One more line reaching every stamped repo. A repo that coins no shorthand never
  triggers it.
- Denser prose in exactly the places already densest — plan walkthroughs and status
  summaries. Rules 4 and 5 exist to keep that cost bounded.
- Unverifiable, like its parent. The only feedback loop is a human saying "what is R3?".

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
  shorthand this rule targets. Rule 3 excludes them by construction.
- **Batch the republish** if both land close together. Two template edits, one
  `sync-plugin`, one version bump, one publish line — rather than two of each.

## Open questions

1. **One bullet or two, on the instruction surfaces?** The decision records must stay
   separate (append-only). The *instructions* need not: a single widened bullet — "gloss
   identifiers and project shorthand alike" — may read better than two adjacent rules that
   both begin "gloss", and invites fewer questions about how they differ. Recommendation:
   **widen the existing bullet in both `AGENTS.md` and `templates/AGENTS.md`, citing both
   records**, and let the record pair carry the history. Owner's call.

2. **Where exactly does rule 3's line fall in practice?** "Decodable without this
   project's context" is the proposed test, and it is a judgment call by design — the same
   kind the existing decay window already is. Worth confirming the owner wants a judgment
   call here rather than an enumerated allow-list of exempt terms, which would rot.

3. **Does the acronym clause need the sandbox tier's vocabulary carved out?** Terms like
   the profile names and tier names recur constantly in cross-repo handoffs. They are
   project-internal by rule 1's test, but they are also stable and documented, which makes
   them feel like vocabulary. Either add "documented and stable" as a second exemption
   route alongside rule 3, or accept that the first mention in each handoff carries a
   short gloss.

4. **Does this want a worked example in the template line, or is the abstract rule
   enough?** The existing template line spends a full clause on an example
   ("the no-scaffolder decision (ADR-0001)"). Shorthand's example would have to be generic
   — a stamped repo has no `R3` — which may make it weaker than no example at all.

## Alternatives

- **Do nothing; the existing rule's spirit covers it.** Rejected: it does not. The record
  enumerates covered identifier kinds and shorthand is not among them, so an agent
  following it literally — the intended mode — leaves "R3 shipped" untouched. The observed
  failures are the evidence.
- **Amend the 2026-08-12 record instead of adding one.** Rejected: decision records here
  are append-only and supersede rather than rewrite. The original also remains correct on
  its own terms; this widens scope rather than replacing a judgment.
- **Put it in the blueprint as a named writing pattern.** Rejected on the same grounds the
  original was: the blueprint argues repository structure, and the template is already the
  delivery vehicle to every consumer.
- **Ship it as a skill.** Rejected: a skill is an invoked procedure. This is a standing
  habit that must apply to every sentence written, which is what an instruction file is
  for.
- **Enforce mechanically.** Rejected: strictly harder than the already-rejected version.
  Ad-hoc codes have no matchable pattern, and glossed text still contains the code.
- **Ban project shorthand outright in human-facing writing.** Rejected: the codes carry
  real value in tables and plans, where they are the compact key to a row. The problem is
  a bare code in *prose*, not the code's existence.
