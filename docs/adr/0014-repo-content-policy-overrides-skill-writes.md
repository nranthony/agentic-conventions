# ADR-0014: A consumer repo's content policy overrides a shared skill's write instruction

- Status: **Accepted**
- Date: 2026-08-25
- Deciders: nranthony + agent
- Extends: ADR-0008 (clickup-work-sync) — which stays Accepted and unmodified
- Distilled from: the `legal` repo's `clickup-pull` report, received through the
  feedback channel 2026-08-25 (ADR-0013), and its triage.

## Context

The shared skills write **tracked files into repos they do not own**. `/myconv:clickup-pull`
is the sharpest case: it creates a `work/NNNN-slug/` item, and that item is committed.

ADR-0008 already governs what crosses the tracker ↔ `work/` boundary, but only on two axes,
and only in one direction:

- **Audience/glanceability** — why body prose does not cross *into* the tracker.
- **Staleness** — why `due`, `priority`, `tags` and assignee stay out of front-matter.

Neither axis is about the *sensitivity* of the content, and the restriction it draws is
inbound. The mirror case — tracker text crossing **out** into a committed file — is
uncovered. Confidentiality does not appear in ADR-0008's reasoning in either direction.

A report from a repo whose own rules forbid identifying detail in tracked files found two
instructions under `## Create the item` that write exactly that: the slug is derived from
the task title, and `## From ClickUp` quotes the task description **verbatim**. In a
matter-organised tracker, titles are named after real parties and descriptions carry the
substance.

Triage found the leak is wider than reported, and that the skill contradicts itself once a
carve-out exists:

- `ClickUp-parent`, `ClickUp-blocked-by` and `ClickUp-related` are all specified as
  `<id> — "<title>"`, and `ClickUp-path` writes `<Space / Folder / List>` names — the same
  class of detail as the title, in five more places.
- The rule **"Never write a bare ID"** requires every relation to carry either
  `→ work/NNNN-slug/` or *its title* plus last-seen status. It therefore **forces the title
  in**, and an agent applying a title carve-out hits a direct contradiction the skill does
  not resolve.
- `## Re-pulling an existing item` reports a diff against current front-matter, so a
  deliberately de-identified body reads as drift on **every** subsequent pull, and the
  obvious remediation is restoring the verbatim text. The carve-out silently undoes itself.

Nothing in this repo contemplates a repo that restricts tracked-file content. The
blueprint's only adjacent line is "Never commit secrets", which is about credentials.

**The same hole runs the other way, and it is worse.** ADR-0008 Decision 1 lets exactly two
things cross `work/` → ClickUp: a status transition and a short exception comment. Every
exclusion behind that — and every line of `/myconv:clickup-report`'s "must not cross" list —
is justified on **glanceability or staleness**, never on sensitivity: *"a tracker's value is
being low-cognitive-load; pasting markdown into it destroys the one thing it is better at
than the repo. If the detail matters, it belongs in the work item."* That reasoning assumes
the work item is the *safer* home for detail. In a repo with content rules the assumption
inverts: the work item is a committed file in a private repo, while a tracker comment is
third-party SaaS, in a workspace that may hold other people, and it cannot be unpublished.
The direction that deserves the stricter rule currently has the weaker one.

This is the fifth instance of the pattern `work/0018-clickup-pull-conformance` Group A
names — *"Any place the skill states what a repo must contain, it should instead state
what it does when the repo contains it, and what it says when it does not"* — and the
first to arrive through the feedback channel rather than by hand. It is materially
stronger than items 1–3 there: those are about repo *shape*, this is about a repo's rules
on *content*.

## Decision

1. **The precedence rule, stated generally.** Where a repo's own rules — its `AGENTS.md`,
   an ADR, or a stated policy — restrict what may enter tracked files, **those rules win
   over any shared skill's instruction to write it.** This is the same posture
   `/myconv:apply-conventions` already takes toward templates ("the repo wins"), generalised
   from repo *shape* to repo *content*, and it holds for every shared skill that writes a
   tracked file, not only `clickup-pull`.

2. **Content classification becomes a third axis** of the tracker ↔ `work/` split, alongside
   ADR-0008's audience and staleness. ADR-0008 stays Accepted and unedited; this record
   extends its decision surface rather than replacing it.

3. **Concretely, in `/myconv:clickup-pull`**, where such a rule applies:
   - the slug derives from the *kind* of work rather than the task title;
   - `## From ClickUp` becomes a restatement **labelled as de-identified**, naming the
     tracker task as the home of the verbatim text;
   - **the same test applies to every field carrying a title or a path** —
     `ClickUp-parent`, `ClickUp-blocked-by`, `ClickUp-blocks`, `ClickUp-related`,
     `ClickUp-path`;
   - a title that cannot be written is replaced by a de-identified descriptor plus
     last-seen status. **Dropping to a bare ID is not the escape** — the never-write-a-bare-ID
     rule still holds, and this is the resolution of the contradiction above;
   - `ClickUp:` id and URL are **always kept**. ADR-0008 Decision 2 already settles this —
     *"the link is a pointer, never a naming scheme"* — and without the pointer the
     restatement cannot be checked against its source.

4. **De-identification is disclosed, never silent.** It is labelled in the file and named in
   the handoff, with the reason. A silent de-identification reads as a lossy pull.

5. **A deliberately de-identified section is not drift.** On re-pull, report that the source
   text changed and let the human decide; never restore verbatim wording an earlier pull
   left out on purpose.

6. **Skills state behaviour, not requirements.** Per Group A: the text says what it does when
   the repo has such a rule and what it says when it does not — it never asserts that repos
   have unrestricted tracked prose.

7. **The rule binds the write direction too, and harder.** Where a repo restricts what may
   enter tracked files, that restriction also governs **what may leave the repo for a
   third-party tracker** — more strictly than it governs a committed file, because the
   tracker is shared, outside the repo's control, and a comment cannot be unpublished.
   Concretely in `/myconv:clickup-report`:
   - **status transitions are always safe.** They carry no content — only a role name
     resolved through `[statuses]`. In a restricted repo this is the whole safe surface, and
     the skill should say so plainly rather than leaving the agent to infer it.
   - **an exception comment names the *shape* of the hurdle, not its content** — "blocked on
     a dependency in another matter", never which matter, whose, or what it says.
   - **"link the item, don't quote it" stands, but its reason changes.** In an unrestricted
     repo the work item is the better home for detail; in a restricted one it is the *only
     permitted* home, and the tracker gets a pointer.
   - **This stays guidance, not enforcement, deliberately.** `comment` and `set-status`
     already sit in the CLI's `ask` permission tier and every write is dry-run first, so a
     human reads the exact text at the prompt. The gate exists; what was missing is telling
     them what to look for.

## Consequences

- The edit is **inert in repos with no such rule**, which is why the report's `conditional`
  verdict was correct and why the cost of accepting the premise is close to zero.
- It creates a **general precedence rule that outlives `clickup-pull`**. That is the reason
  this is an ADR and not a skill edit: the statement is guardrail-class and reaches every
  shared skill that writes tracked files.
- **Coverage widens from two instructions to seven fields plus the re-pull path.** That is
  deliberate and is the part most worth challenging — see the open question below.
- It adds a judgment call to the pull ("does this repo have such a rule?"), answered by
  reading the consumer's own `AGENTS.md` — which the skill should be doing anyway.
- **The record is two-directional.** Decisions 1–6 govern tracker → committed file;
  Decision 7 governs repo → tracker. Splitting them across two ADRs was rejected: they are
  one precedence rule with two blast radii, and the write direction is the one a reader is
  most likely to miss, since ADR-0008's existing prose reads as if it already covered it.
- ADR-0008's context bullet about the tracker ↔ `work/` axes is not wrong, only incomplete;
  no erratum is required because no claim it makes becomes false.
- Ships as a **0.7.0 surface change**, batched with `work/0018` and `work/0014` — the exit
  cycle (`just sync-plugin` → `just check` → CHANGELOG → bump both manifests → republish →
  host re-vendor) is too expensive to spend twice for one carve-out.
- Per ADR-0013 §7, the `CHANGELOG.md` entry names the originating report. That is the only
  reply the reporter gets.

## Scope taken

**The wide coverage was signed** (2026-08-25). The reported defect was two instructions; the
record fixes seven fields plus the re-pull path, because two of the three additions are not
extra coverage at all — they are correctness of the narrow fix. Without the bare-ID
resolution the skill ships two mandatory rules in conflict with no stated way out; without
the re-pull clause the carve-out reverses itself on the next pull while appearing to work.
The genuinely discretionary addition is the five title/path front-matter fields, taken on the
grounds that they carry the same class of detail and that the reporter's silence about them
is explained by their task having no relations. `ClickUp-path` is the weakest member — Space
and Folder names are organisational and may not identify anyone — so it is worded as "apply
the same test", not as a flat rule.

## Alternatives considered

- **Fix only the two reported instructions.** Leaves five fields leaking the same class of
  detail, and hands the next agent an unresolved contradiction with the never-write-a-bare-ID
  rule. Rejected as a half-measure that reads as complete.
- **Amend ADR-0008 in place.** Rejected on the append-only rule. ADR-0008's existing erratum
  is precedent for correcting a *supporting claim* while the decision stands; this is a new
  decision, and appending it would be rewriting-by-append.
- **Drop relations to bare IDs when titles cannot be written.** Rejected — ADR-0008 and the
  skill both call a bare ID decorative, and it destroys the reasoning value the relation
  exists for. A de-identified descriptor keeps it.
- **Make the whole pull opt-out in restricted repos.** Rejected: the pointer, status, path
  shape and dependency graph are exactly the parts that leak nothing and carry the value.
- **A separate ADR for the write direction.** Rejected — see the two-directional consequence
  above. One rule, one record; two records invite a reader to apply half of it.
- **Enforce the write rule in the CLI** (a length cap, a content filter on `comment`).
  Rejected: a filter that cannot read the repo's rules would either block legitimate comments
  or pass the ones that matter, and it would put a confidentiality decision inside a tool
  that ships to every consumer. The `ask` tier already puts a human on the exact text.
- **Leave it to each repo's local workaround.** What the reporter did, correctly, under the
  one-way rule — but it makes every restricted repo re-derive the same carve-out, and the
  next one may not notice the five front-matter fields either.
