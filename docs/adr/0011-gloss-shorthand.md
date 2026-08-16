# ADR-0011: Gloss shorthand, not just identifiers

- Status: Accepted
- Date: 2026-08-16
- Deciders: nranthony + agent
- Extends: ADR-0010 (which stays Accepted and correct on its own terms — this widens its
  scope rather than replacing a judgment)
- Distilled from: `work/0015-gloss-shorthand/proposal.md`

## Context

ADR-0010 fixed the habit of glossing an identifier before citing it, and enumerated what
counts: decision numbers, work-item slugs, section numbers, external ticket IDs. Every one
of those is a **manufactured identifier with a canonical home** — a thing that exists on
disk under a name you can grep.

That list has a hole its own reasoning does not survive. Agents here also coin **shorthand
in flight**: plan-item letters, task-table codes, question numbers, codenames, acronyms.
Recent cross-repo exchanges produced "R3 shipped", "B0–B7 are theirs", "T5 is open",
"E13 blocks the mapping". Each was clear to the agent that coined it and opaque to the
human reading cold, and to the next agent opening a fresh session.

**Shorthand is the worse case, not a milder one.** ADR-0010 rests on an asymmetry: a bare
"ADR-0005" costs the agent a grep and costs the human a context switch, so the cost belongs
on the writer. Shorthand breaks even that. "R3" frequently has no canonical home at all —
it resolves only against *which* plan, *whose* table, *which* exchange coined it. A fresh
agent grepping `R3` gets nothing useful, so the reader absorbs the same context switch plus
an ambiguity the identifier case never had.

The hole is structural rather than incidental. ADR-0010 enumerates covered identifier
*kinds*; shorthand is not an item omitted from that list but a category the list was never
written to admit. No charitable reading of the existing record closes it, and an agent
following it literally — the intended mode — leaves "R3 shipped" standing.

## Decision

**1. Project-internal shorthand glosses, on the same pattern.** Name the thing in plain
language, then cite the code: "the task-move command (R3 in the plan) shipped", never "R3
shipped"; "the bootstrap steps (B0–B7) are theirs", never "B0–B7 are theirs".

**2. The obligation is to convey what the thing *is*, which separates a name from a code.**
A name plus its category word already discharges it — "the `nranthony` profile" says what
kind of thing it is and is unique enough to look up. A code plus its category word does
not: "the R3 plan item" says where to look and nothing about what it is, so only "the
task-move command (R3)" pays the debt. This is why the ecosystem's stable internal
vocabulary — the channel, member repos, the deployment tier — costs at most a category
word: those were named in English, so the name is already the gloss.

**3. Acronyms expand on first use when the reader may not hold them.** Audience judgment,
the same species as ADR-0010's decay clause, not a mechanical always-expand.

**4. Genuine technical vocabulary is not the target, and three tests bound it.** "Wheel",
"manifest", "rebase", "lockfile" are the plain terms; there is nothing to gloss them into.
Apply the tests in the order they are cheapest:

- **Provenance (author-side, first).** Did this project coin it? If yes, gloss. The writer
  already knows the answer without simulating a reader, and it settles every observed
  failure immediately.
- **Findability (tiebreak).** Could the reader resolve it without opening a document
  someone here wrote? A search result or a man page means vocabulary.
- **Decodability (tiebreak).** Could a competent outsider reading cold get the right
  answer? The most correct test and the slowest; reserved for the genuinely unclear case.

**When still unsure, gloss.** The error costs are lopsided — over-glossing costs a few
words and reads mildly explanatory, under-glossing costs the reader the exact failure the
rule exists to prevent. The default follows from the asymmetry and lets a writer decline
the boundary question instead of having to answer it.

**5. Enumerations gloss the set, not each member.** "The seven bootstrap steps (B0–B7)"
discharges the whole range; walking the table row by row afterwards does not re-gloss every
code. Stated rather than inferred, because this is where decision 1 read naively would cost
the most.

**6. Shorthand is defined at coinage.** A code introduced by a numbered list or table
within the same response is glossed *by that list*; prose referring back to it may use the
bare code. A row keyed `R3 | move a task between lists` is itself the gloss.

**7. ADR-0010's edges are inherited unchanged.** Human-facing surfaces only — assistant
responses, commit and PR text, and docs a human reads, which includes proposals, plans and
handoffs, since the owner is their primary reader; agent-internal cross-references stay
code-first. Repetition decays at agent discretion. Write-once artifacts gloss on first
mention with no decay.

**8. The records stay separate; the instruction surfaces merge.** Records here are
append-only, so this is a second record rather than an edit to the first. The *instruction*
has no such constraint, and two adjacent bullets both opening with "Gloss" would invite an
agent to read the first, recognise the pattern, and skip the second as a restatement —
dropping precisely the half that is newer and less intuitive. Scope, decay and the
write-once carve-out are identical across the two, so two bullets would pay for the shared
edges twice in files where every line competes for attention. One widened bullet replaces
the existing one in `AGENTS.md`; one widened line replaces the existing one in
`templates/AGENTS.md` under Golden rules, carrying a worked example for each half in
contrast form. Neither lands in `reference/agentic_native_repo_scaffold.md` — a writing
habit is not repository structure — and neither becomes a skill, since a skill is an
invoked procedure while this must hold for every sentence written.

**9. Advice, not enforcement — more firmly than before.** A correctly glossed sentence
still contains the code, so no grep separates compliant from bare text. Shorthand is
strictly less lintable than `ADR-\d+`: there is no pattern to match, because the codes are
coined ad hoc by construction.

## Consequences

- The template line grows from three lines to five, making it the longest of three Golden
  rules in a file every stamped repo receives. Accepted: this is one of the house's
  signature habits, and the negative half of each example ("not `per ADR-0001`") is what
  teaches the rule.
- A reader who follows the merged bullet's first citation can land on ADR-0010, which says
  nothing about shorthand. That is why decision 8 is written down here, on the record side,
  where someone reading for history will find it.
- Prose gets denser in the places already densest — plan walkthroughs, status summaries.
  Decisions 5 and 6 exist to bound that; a repo that coins no shorthand never triggers the
  new half at all.
- Compliance stays unverifiable, like its parent's. The only feedback loop is a human
  asking "what is R3?".
- Two agents will draw decision 4's boundary differently. The when-unsure default means
  they err toward the cheap failure.

## Alternatives considered

- **Rely on ADR-0010's spirit** — rejected: it enumerates kinds, shorthand is not among
  them, and the observed failures are the evidence that literal reading wins.
- **Amend ADR-0010** — rejected: records here are append-only and supersede rather than
  rewrite, and the original needs no correction.
- **Two bullets on the instruction surfaces** — rejected under decision 8: the second reads
  as a restatement and gets skipped.
- **An enumerated allow-list of exempt technical terms** — rejected on a stronger ground
  than rot. The list would live in `templates/AGENTS.md` and ship to repos whose vocabulary
  has nothing to do with this one's, so it was never alive outside this repo to begin with.
- **A second exemption route for documented, stable vocabulary** — rejected: decision 2
  dissolves the need. A route would require maintaining and would invite argument over
  whether a term is "stable enough", a question with no answer and no upside.
- **Drop the worked example from the template, since a stamped repo has no `R3`** —
  rejected: the existing example has the same property (a stamped repo's ADR-0001 is
  almost certainly not the no-scaffolder decision). The example demonstrates shape, not
  content, and shape matters more here — "gloss identifiers" is nearly self-executing,
  while recognising that what you just typed *was* shorthand is the whole difficulty.
- **Enforce mechanically** — rejected under decision 9, more decisively than ADR-0010
  rejected it.
- **Ban project shorthand outright in human-facing writing** — rejected: the codes are the
  compact key to a table row and earn their place there. The defect is a bare code in
  *prose*, not the code's existence.
