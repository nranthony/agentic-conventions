# ADR-0010: Gloss identifiers before citing them

- Status: Accepted
- Date: 2026-08-12
- Deciders: nranthony + agent
- Distilled from: `work/0004-gloss-before-cite/proposal.md`

## Context

This repo manufactures identifiers at a fast clip — ADR numbers, `work/NNNN-slug/` items,
ClickUp task IDs — and agents reference them constantly in chat, commit messages and docs.

A bare identifier splits the recall cost unfairly. For an agent, resolving "ADR-0005" is a
grep: cheap, exact, forgettable and refindable at will. For the human reading the same
sentence it is a context switch — stop, open the file, reorient, reload what the decision
said, come back. Left unstated, the habit quietly offloads the lookup onto the person least
able to absorb it in-context.

The convention is not lintable. A correctly glossed line still contains the identifier, so no
mechanical check can tell compliant text from bare text; false positives would be pure noise.
That places it on the advice side of the blueprint's advice-versus-enforcement split, and
advice lands as prose or not at all.

## Decision

**1. Gloss, then cite.** State the substance in plain language; append the identifier
parenthetically, after the point has landed — "the reference-not-automation decision
(ADR-0001)", never "per ADR-0001, ...".

**2. Scope: human-facing surfaces only.** Assistant responses, PR and commit descriptions,
user-visible docs. Agent-internal cross-references stay code-first: an ADR's "Alternatives
considered", a proposal's `Accepted → ADR-NNNN` status line, skill-to-skill pointers. They are
read by an agent, or by a human already deep in the doc trail, who resolves them cheaply.

**3. Covered identifiers: decision and doc IDs only** — ADR numbers, work-item slugs, section
numbers, external ticket IDs. Explicitly **not** `file:line` references or git SHAs: those are
directly actionable (click-to-open, `git show`) rather than a memorized lookup, and citing
them bare is already this repo's practice.

**4. Repetition decays, at agent discretion.** Once glossed, later mentions of the same
concept within the same exchange may drop to the bare identifier. The window ("roughly the
last response or two, sized to what a reader plausibly still holds") is a judgement call and
stays one — a firmer rule such as "same response only" would be measurable but wrong as often
as it was right.

**5. Write-once artifacts gloss on first mention, with no decay.** A PR description or commit
message is read once, out of conversational order, with no preceding turn to have carried the
gloss. Decay has nothing to decay from there.

**6. It lands in both `AGENTS.md` and `templates/AGENTS.md`, and not in the blueprint.** Three
lines here, one in the template's Golden rules. It stays out of
`reference/agentic_native_repo_scaffold.md`: the blueprint argues structure, and this is a
house writing habit that the template already carries to every repo that adopts it.

## Consequences

- Consumers of the plugin receive the rule in the template's Golden rules, so it propagates
  without the blueprint arguing for it. A repo that never accumulates identifiers simply never
  triggers it — the cost of carrying it is one line.
- Compliance is unverifiable by construction. The only feedback loop is a human noticing a
  bare identifier and saying so; there will be no report telling anyone how often it is
  followed.
- Glossing costs words. In dense agent-to-human summaries that cite several decisions, the
  prose gets longer — accepted, since the alternative spends the reader's time instead.
- The decay window being discretionary means two agents will draw it differently, and
  occasionally a reader gets a bare identifier they had lost track of. Cheaper than the
  re-gloss noise a strict rule would produce.

## Alternatives considered

- **Ban bare identifiers everywhere, agent-internal references included** — rejected: it
  trades away the low-cost, high-precision value identifiers have in ADR chains and status
  lines, for no benefit to a reader who can grep instead of recall.
- **Enforce mechanically (a CI or hook grep for bare `ADR-\d+`)** — rejected: a glossed line
  still contains the identifier, so the check cannot distinguish compliant from
  non-compliant. Reconsiderable only if someone finds a signal that does distinguish them.
- **A firm decay rule ("same response only")** — rejected under decision 4: measurable, but
  it forces re-glossing across adjacent turns of one conversation, which reads as talking
  down to the reader.
- **Document it in the blueprint as a named pattern** — rejected under decision 6: the
  blueprint is about repository structure, and the template is already the delivery vehicle.
- **An opt-in flag requested per conversation** — rejected: a durable default-on habit was
  wanted, not a thing to remember to ask for.
