# Handoff: the work-item status vocabulary — this item moves to your repo

**To:** the agent working in `agentic-conventions`
**From:** the agent in `myclickup`
**Date:** 2026-08-16
**Reciprocal-to:** —
**Filed at:** `work/0013-work-item-status-alignment/handoff-agentic-conventions-transfer.md`
(archived with its item) · delivered: copied to your `inbox/`

**Owner decision, 2026-08-16:** this task belongs in your repo, not in
`myclickup`. The contract it refines is yours — the board-sync decision record
(your ADR-0008) fixes field ownership and says status is the only shared field
— and the vocabulary should bind every repo the conventions stamp, not one
member. The full proposal stays archived in myclickup
(`work/archive/0013-work-item-status-alignment/proposal.md`, survey tables and
alternatives included); this is the condensed transfer.

**Context, not a directive:** the owner will follow up with a research document
in this same inbox and the vocabulary applies from that point. Do not start
work from this handoff alone.

## 1. The problem, condensed

- Work-item status lines have no defined vocabulary. Only the proposal template
  ever had one, and the folders on disk used eight spellings for roughly seven
  states (surveyed 2026-08-14 in myclickup). The drift has **grown** since:
  the 2026-08-15/16 archive sweep added spellings like "Complete · archived"
  and "Closed" that match no list either. Nothing can gate on a status nobody
  defined.
- The relationship between a local status and a board update is decided but
  recorded nowhere — it is inferable only by reading the reporting skill
  (`/clickup-report`).

## 2. The proposed shape, condensed from the full proposal

1. **One vocabulary** for all three document kinds (proposal / spec / plan):
   `Draft` → `In review` → `Approved <date>` → `In execution <date>` →
   `Complete <date>[ → ADR-NNNN]`, plus `Blocked — <reason>`,
   `Deferred — <reason>`, `Rejected <date> — <reason>`. The reason clause is
   mandatory on those last three — they are worthless without one.
2. **Two axes stay separate.** The board status measures *who holds the item*
   in the human workflow; the local status measures *how mature the artifact
   is*. Local names must never collide with board names, so two different
   things cannot masquerade as one field.
3. **Three edges only, one direction**, written by the reporting skill and
   nothing else: work started (`In execution` ⇒ the agent-working role), work
   stuck (`Blocked` ⇒ the hand-back-to-human role, never gated), work finished
   (`Complete` ⇒ the complete role, exit rule satisfied first). Every other
   local status is local-only and never touches the board.

## 3. Answers and notes from the myclickup side, 2026-08-16

- **Open question 1 — where does the record live: answered by the owner.**
  Here, in your repo, landing directly. The sequencing worry dissolved when
  the distribution channel became the only door (myclickup ADR-0014, Accepted
  2026-08-16): you are the upstream origin, and the change ships like any
  release — plugin republish through the channel.
- **Open question 2 — one vocabulary for all three document kinds:** the
  recommendation is assume yes and split only if it reads badly in practice.
  The weak spot is a spec's `Draft`, since a spec arrives already decided.
- **Open question 3 — `Approved` vs widening `Accepted`:** the argument for
  `Approved` is search cleanliness — reserve "Accepted" so a search finds only
  decision records. Real but small; an owner taste call, still open.
- The full proposal's migration table is **stale** — several items it maps
  were archived after it was written. Refresh the mapping when applying.
- One consumer is already waiting: myclickup's pipeline proposal (its
  work/0014) is explicitly gated on this vocabulary — a gate needs a
  parseable status. Expect the same shape to be wanted wherever the
  conventions are stamped.

## 4. What the myclickup side did, and what it waits on

The item is closed and archived there, pointing here. Nothing in myclickup
moves until your decision lands; the migration pass over its `work/` folder
applies the vocabulary afterwards, in one pass.

**Closing state:** myclickup owes nothing further on this; the next artifact is
the owner's research document, arriving in this inbox.
