# Proposal: Gloss before cite — human-facing references to decision/doc IDs

- Status: Draft
- Author: nranthony + agent
- Migrated from `docs/rfcs/gloss-before-cite.md` ([ADR-0006](../../docs/adr/0006-proposals-are-work-items.md))

## Summary

Proposes a communication convention, not a code change: when an agent addresses a
human (chat responses, PR/commit descriptions, user-visible docs) and needs to
reference a prior decision — an ADR number, an RFC slug, a section number, an
external ticket ID — it states the decision in plain language first and appends the
ID afterward in parentheses for provenance. It never leads with, or relies on, the
bare ID alone. Example: "We decided to route proposals through docs/rfcs/ before an
ADR (ADR-0005)" instead of "Per ADR-0005, ...". Agent-internal references (ADR
cross-links, memory `[[slug]]` links, skill-to-skill pointers) are unaffected.

## Motivation

A bare ID splits recall cost unfairly. For an agent, resolving "ADR-0005" is a grep —
cheap, exact, forgettable-and-refindable at will. For the human reading the same
sentence, it's a context switch: stop, open the file, reorient, reload what the
decision actually said, come back. Agents in this repo produce exactly this kind of
ID at a fast clip (ADR-####, RFC slugs) and reference them constantly in chat and
commit messages; without a convention, that referencing pattern quietly offloads the
lookup cost onto the person least equipped to absorb it in-context.

## Proposal

1. **Scope: human-facing surfaces only.** Assistant chat responses, PR/commit
   descriptions, user-visible docs. Agent-internal cross-references — an ADR's
   "Alternatives considered" section, memory-file `[[slug]]` links, skill-to-skill
   pointers, an RFC's `Status: Accepted → ADR-NNNN` line — are exempt and stay
   code-first, since they're read by an agent (or a human already deep in the doc
   trail) that can resolve them cheaply.
2. **Pattern: gloss, then cite.** State the substance in plain language; append the
   ID parenthetically, after the point has already landed.
3. **Covered IDs: decision/doc identifiers only.** ADR-####, RFC titles/slugs,
   section numbers, external ticket IDs (Linear/JIRA/etc.). Explicitly **not**
   covered: `file:line` references and git SHAs — these are directly actionable for
   a human (click-to-open, `git show`) rather than a memorized lookup, so citing
   them bare is fine and already this repo's practice.
4. **Repetition decays.** Don't re-gloss the same concept every time it's mentioned.
   Once explained in a response, later mentions within that same response — and
   within roughly the last response or two, sized to what a reader plausibly still
   holds — may drop straight to the bare code.
5. **Enforcement: advice, not a mechanism.** Per the scaffold's "Advice vs.
   enforcement" split, this isn't lintable — a correctly-glossed line still contains
   the code, so a mechanical check can't distinguish glossed from bare. It lands as
   prose in `AGENTS.md` (this repo) and `templates/AGENTS.md` (so it propagates to
   repos that adopt the template), not as a hook or CI gate.

## Open questions

- Exact landing spot: its own short section in `AGENTS.md`, folded into the
  scaffold's "Golden rules" example, or both.
- Does `reference/agentic_native_repo_scaffold.md` want a documented mention of this
  as a pattern, or does it stay scoped to `AGENTS.md`/`templates/` as a house rule
  specific to this repo's own heavy ADR/RFC usage?
- "Last response or two" is a judgment call, not a measurable window. Acceptable as
  agent discretion, or does it need a firmer rule (e.g., "same response only")?
- PR/commit messages are read once, out of conversational order — does the
  repetition-decay clause even apply there, or should every such artifact gloss on
  first mention with no decay?

## Alternatives

- **Ban bare codes everywhere, including agent-internal references:** rejected —
  trades away the low-cost, high-precision value codes provide in ADR chains and
  memory-file links, for no benefit to agents that can grep instead of recall.
- **Enforce mechanically (CI/hook grep for bare `ADR-\d+`):** rejected for now — a
  properly glossed line still contains the code, so the check can't tell compliant
  from non-compliant text; false positives would be noise. Stays advice per the
  scaffold's advice-vs-enforcement split.
- **Opt-in flag, invoked per conversation:** rejected — a durable default-on
  convention was preferred over asking for it each time.
