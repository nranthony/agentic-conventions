# Proposal: a defined vocabulary for work-item status lines

- Status: In review
- Author: agent (Opus 5) + nranthony, from `myclickup`'s transferred item
- Opened: 2026-08-26, promoting a handoff that had sat in `inbox/` since 2026-08-16
- Source: `transfer-from-myclickup.md` beside this file — the condensed transfer. The
  full original, with survey tables and alternatives, stays archived in `myclickup`
  (`work/archive/0013-work-item-status-alignment/proposal.md`).

## Why this is open again

The transfer was delivered ten days ago and closed with an instruction: *"the owner will
follow up with a research document in this same inbox and the vocabulary applies from
that point. Do not start work from this handoff alone."* **That document never arrived.**
Meanwhile the drift it describes kept growing — eight spellings for roughly seven states
at the 2026-08-14 survey, with the archive sweep since adding "Complete · archived" and
"Closed", neither of which matches any list.

One consumer is already blocked on it: `myclickup`'s own pipeline item is gated on a
*parseable* status, and a gate cannot key on a value nobody defined.

## Decided — the paused state (2026-08-26)

**`Deferred — <reason>`**, with the reason clause mandatory. Applied today to the three
places the status enum is written down: this repo's `work/README.md`,
`templates/work/README.md`, and the blueprint's work-item section.

Two reasons it beat following the tracker's own label ("On Ice"):

1. **The transfer's rule 2 already forbids it** — *"local names must never collide with
   board names, so two different things cannot masquerade as one field."* The two axes
   measure different things: the board status says who holds the item, the local status
   says how mature the artifact is.
2. **A status name is not portable.** ClickUp defines statuses per Space with per-List
   overrides, which is exactly why `[statuses]` exists as a role→name map and why the
   standing rule is never to hard-code one. Baking a Space's spelling into the blueprint
   would put one workspace's label in text every repo reads — including repos with no
   tracker at all.

**No `[statuses]` mapping is needed, and adding one would be wrong.** An earlier
suggestion in this thread was to map the role to "On Ice" on the board; the transfer
settles it better. `Deferred` is **local-only** — only three edges ever cross to the
tracker (work started, work stuck, work finished), and paused is not among them. There is
nothing to map because the state never leaves the repo.

**The reason clause is the load-bearing half.** `/myconv:wrap-up` §7 exists precisely
because a paused item's label reads as "deliberate, nothing to do here" and hides whether
its premise still holds. A bare status word would reintroduce that.

## Still open — the rest of the vocabulary

Not decided, and deliberately not implemented from the transfer alone:

- **The full enum**: `Draft` → `In review` → `Approved <date>` → `In execution <date>` →
  `Complete <date>[ → ADR-NNNN]`, plus `Blocked — <reason>` and
  `Rejected <date> — <reason>`. Today's change adds one member to the existing enum; it
  does not adopt this shape.
- **One vocabulary for all three document kinds?** The transfer recommends yes, splitting
  only if it reads badly. Its own weak spot: a spec's `Draft`, since a spec arrives
  already decided.
- **`Approved` vs widening `Accepted`.** Argued on search cleanliness — reserving
  "Accepted" so a search finds only decision records. Owner taste call.
- **The three board edges**, written by `/clickup-report` and nothing else. This is the
  part that touches an accepted ADR's field-ownership decision and needs the most care.
- **The migration pass.** The transfer's mapping table is stale — several items it maps
  were archived after it was written. Refresh before applying, in both repos.

## Exit

The decided slice shipped in the status enum. The remainder either gets the owner's
research document and lands as one vocabulary change, or is closed as "the enum plus
`Deferred` is enough" — but it should not sit undecided for another ten days while the
spellings multiply. Whichever way it goes, the rationale distils into an ADR: it binds
every repo the conventions stamp, which is what made `myclickup` transfer it here rather
than decide it locally.

**Not in 0.7.0.** Today's change is queued for the next release; the 0.7.0 being
re-vendored does not contain it.
