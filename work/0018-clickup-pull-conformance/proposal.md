# Proposal: `/clickup-pull` conforms to the repo it runs in, and never skips silently

- Status: Draft
- Author: agent (Opus 5) + nanthony
- Opened: 2026-08-18, from consumer feedback raised in the `myclickup` repo
  (two pulls, 2026-08-17). Opened as `0017`, renumbered to `0018` the same day:
  a concurrent session claimed `0017` for the skill-feedback-channel item minutes
  later, and yielding the number was cheaper than renumbering an item still in
  flight. Numbers are never reused, so `0017` stays theirs.

## Summary

Eight defects in `.claude/skills/clickup-pull/SKILL.md`, all policy, none needing a
CLI change. They fall into two groups: the skill **asserts a repo shape** instead of
reading the one in front of it (four), and the skill **skips things without saying
so** (four). Fix both groups in one pass, because splitting them means writing the
same rule into the skill twice in slightly different words.

The write path (`/clickup-report`) is deliberately out of scope — see item 1 below.

## Motivation

The feedback came from `myclickup`, whose two pulls both hit the same wall and both
proceeded on a value typed into the prompt. Neither the wall nor the workaround is
recorded anywhere a later reader would find it.

The pattern is not new. The end-of-thread skill (`/wrap-up`) already solved it: its
§0 detects what the repo keeps, skips absent pieces silently, and refuses to propose
adding opt-in machinery. `/clickup-pull` never inherited that posture — while, in a
single sentence, telling the agent to use "the repo's own proposal template headings."
It defers for headings and asserts everything else.

The second group has a decided answer too. The packaging recipes already say it, of a
check that stood down instead of answering: *"A skip is not a pass; say so where it is
read"* (`justfile`, the `check` recipe). A pull that silently omits a comment thread or
an oversized attachment is that failure in a second place.

## Proposal

### Group A — conform to the repo, don't assert a shape

1. **A missing status-role table is a state, not an error** (preflight step 5).
   Today the skill says "say which key is missing and stop," which fires on every
   pull in a repo that deliberately does not pin the table. The `myclickup` repo is
   exactly that case: its pin file carries no `[statuses]`, with the reason stated at
   the top of the file — the repo tracks work in `work/`, not on the board. Both pulls
   there proceeded on a status name typed into the prompt, with the agent left to
   decide on its own that continuing was allowed.

   Instead: treat a caller-supplied status name as the missing pin **explicitly**.
   Name it as supplied-not-pinned, validate it against what the list actually defines
   (`myclickup statuses --list "<path>" --live`, matched case-insensitively per the
   lower-casing the skill already documents), and record in the item that the role
   mapping came from the caller. The read is already in the skill, so validation is
   free.

   **Read path only.** A status name typed into a prompt that drives a *board write*
   is a different risk class from one that drives a read. `/clickup-report` keeps
   requiring a pin or an explicit confirmation of the exact name. This convenience
   must not leak across.

2. **Defer on the filename.** The skill hard-codes `proposal.md`; the lifecycle
   (`work/README.md`) says an item opens as a `proposal.md` *or, for pre-decided work,
   straight as a `spec.md`/`plan.md`*. A task already on a board is pre-decided almost
   by definition, so `spec.md` is frequently the correct choice — and it is what the
   previous pull used. Read the repo's `work/README.md` and its existing items; follow
   them. Default to `spec.md` for a pulled task unless that repo's lifecycle says
   otherwise.

3. **Pin the front-matter placement: title first, then the `- Key: value` block.**
   The skill's example shows the block bare, which reads as "the file starts here."
   Both the proposal template in `work/README.md` and the observed pull put it under
   the `#` title. This is the part meant to be machine-readable later, so the
   ambiguity is worth closing rather than leaving to taste. Pin it in
   `templates/work/README.md` as well — that fenced example carries the same ambiguity
   to every consumer.

4. **Adopt `/wrap-up`'s detect-then-conform posture wherever else it applies.** Items
   1–3 are instances; the sweep is the deliverable. Any place the skill states what a
   repo must contain, it should instead state what it does when the repo contains it,
   and what it says when it does not.

### Group B — never skip silently; make the omission auditable

5. **Check comments.** Nothing today tells the agent to look. A task whose real scope
   lives in a comment thread pulls as an empty description with no hint anything was
   missed. Add `myclickup comments <id> --json --live` to the Pull section. Always
   check; record the count and last-commented date **even when there are none**, so
   "checked, nothing there" is distinguishable from "never looked."

6. **List attachments that were not pulled** — in a `## Attachments` body section, not
   front-matter. The existing front-matter rule excludes anything that "changes no
   agent behaviour and goes stale silently," and a size-and-URL manifest is exactly
   that shape. A body section also allows the skill's own "never write a bare ID" rule
   to be honoured: title, type, size, and the reason it was left behind.

7. **Record provenance for what is pulled — but never the URL.** Attachment URLs are
   signed, so a tracked file would carry an expiring credential, and it is the wrong
   drift signal regardless. Record `id`, `title`, `mimetype`, `size`, `version`, the
   ClickUp `date`, and the pulled-date. A replaced attachment bumps `version` and
   `date`, which gives drift detection with no hashing and no re-fetch.

8. **Surface what the CLI skipped.** The download never overwrites — an existing file
   is skipped and reported, per the attachment-download decision in `myclickup`
   (`docs/adr/0010-attachment-downloads.md`, rule 4, shipped 2026-08-12). The skill's
   only job is to report that `skipped` array rather than swallow it. This needs no
   new mechanism; it is the never-clobber rule the feedback asked for, already built.

### Deferred to a follow-up — the download gate itself

Auto-downloading text-ish attachments under a size cap is **not implementable today**
and is not part of this item. The download is all-or-nothing per task: the skill can
compute the decision from `attachments <id> --json` (the raw objects carry `mimetype`,
`size`, `extension`, `version`), but cannot act on it without also fetching the large
binary the cap exists to avoid. Two things gate it, both outside this repo:

- a selector in the CLI (`--only <attachment-id>`, repeatable) so the caller can act
  on a decision it has already made — keeping *which files* in the skill and *the
  fetch* in the CLI, per the split the CLI-first rewrite settled (work/archive/0013).
  Written up as `handoff-myclickup-attachment-selection.md` beside this file;
  **not yet delivered** — see its Delivery section for why that is a deliberate step;
- an egress allowlist entry for the attachments host,
  `t90141509251.p.clickup-attachments.com`, which The Vault does not have. Landing the
  gate without it ships a feature that fails at the proxy on first use, in the one
  environment it is for. A human step in the sandbox repo.

Items 6–8 are the reporting half of the same feature and are unblocked by both.

## Open questions

- **One decision record or two?** Group A is the same argument the wrap-up generality
  item (`work/0014`) is making about a different skill. Recommendation: fold Group A
  into 0014 so one record covers both skills — writing it twice is how two divergent
  rules appear. Group B needs no new decision; it is the existing "a skip is not a
  pass" rule applied in a second place.
  *Recorded 2026-08-18* in 0014's review section, which states the generalised
  principle and treats this item's Group A as its application. Still open in the sense
  that the owner has not ruled on it — but the argument no longer needs restating.
- **How far does "read the repo" go?** Parsing `work/README.md` is deterministic;
  inferring the lifecycle from existing item filenames is heuristic. Does the skill
  stop when a repo has neither, or pick a default and say which?
- **Does the supplied-status path need a ceiling?** If a repo never pins the table,
  every pull re-validates a typed name. Acceptable, or should the skill offer to write
  the pin once it has confirmed the name against the live list?

## Alternatives

- **Patch the four reported notes only.** Rejected — they are four instances of two
  root causes, and patching instances leaves the next instance to be reported by the
  next consumer. The `/wrap-up` §0 posture already exists to be copied.
- **Make the status-role table mandatory** and fix the consumer instead. Rejected: the
  absence is a documented decision in a repo that legitimately does not track work on
  a board. A shared skill that only works in repos shaped like this one is not shared.
- **Ship Group B's attachment items with the download gate.** Rejected — the reporting
  half is unblocked and the gate is not, so coupling them would hold a working fix
  behind an egress change in a third repo.

## Exit

Both groups land in `.claude/skills/clickup-pull/SKILL.md`; item 3 also touches
`templates/work/README.md`. Group A's rationale distils into the wrap-up generality
record (`work/0014`) if that fold is accepted, or its own record if not. Then:
`just sync-plugin`, `just check`, a CHANGELOG entry, a version bump in both plugin
manifests, republish through the channel, and re-vendor host-side. Consumer-visible,
so it batches with 0014 into one release rather than spending a cycle alone.
