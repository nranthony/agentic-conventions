# Handoff: one recipe to consume a channel release

**To:** the agent in `macolima` (host side), via the owner — macolima has no inbox, so this
is human-ferried
**From:** the agent in `agentic-conventions`, working from the channel (`depot`)
**Date:** 2026-09-15
**Filed at:** `agentic-conventions/work/0025-triage-skill-feedback/handoff-macolima-consume-recipe.md`
**Kind:** a proposal, not a request. macolima's own rules decide — including never
blind-copying from the sibling sandbox repo.

## 1. What consuming a release cost on the Mac

myconv 0.9.0 → 0.10.0, run by the owner on the host, 2026-09-15: `tools-check` (drift on
`myconv.tree`), `vendor-tools`, `tools-check` (green), then `converge` once per profile and a
restart. The steps are recorded once, in the channel's `AGENTS.md` under "Consuming a
release" — readable on the Mac at the channel's recorded path.

Verified from inside the `nranthony` container afterwards: all six seeded `VERSION`
sidecars read `myconv 0.10.0` with the channel's hashes, written by `converge`. No build and
no recreate were needed.

Two things made it longer than it had to be:

- `vendor-tools` ends with `Next: just build` / `Then: just recreate <p>` **every time**.
  Only a wheel change needs either; this release changed none, so following the advice
  would have cost a rebuild that changed nothing.
- The profile list was typed by hand. A new profile would be missed silently.

## 2. Proposal: one consume recipe (name it as you like)

1. `tools-check`. Green → say so and exit 0.
2. `vendor-tools`.
3. `converge` every profile `just list` reports, rather than a typed list.
4. Read the `VENDORED.lock` diff that step 2 produced:
   - a `.wheel` row moved → print `just build`, then `just recreate <p>` for each **running**
     profile;
   - no `.wheel` row moved → say explicitly that no rebuild is needed.
5. A wheel row moved **and** that tool's `proposed_allow` / `proposed_ask` / `proposed_deny`
   changed in the manifest → run `check-permissions`. `vendor-tools` prints
   `not a scalar, skipped by the mirror` for those lists, so the lock never carries them, and
   a green `tools-check` says nothing about permissions.
6. Print the restart line.

With that in place, the channel's `AGENTS.md` "Consuming a release" section can quote one
command, and `/myconv:triage-skill-feedback` — which composes its closing host block from
that section — shrinks the Mac's part of the block to one line.

## 3. Two things noticed, for you to weigh

- **`converge`'s overwrite warning can't tell a release from an edit.**
  `skill 'myconv' differed from the template — OVERWRITTEN … no backup kept` fired for every
  profile, because each seeded copy was 0.9.0. It reads identically when someone has edited
  a seeded copy in place. Comparing the seeded `VERSION` sidecars with the template's first
  would separate the two: if the sidecars differ, it's a release.
- **`tools-check` is hash-and-lock only.** It says so: `the artifacts are NOT
  content-checked against their source_commit yet`. The same consumer check on the Win11/WSL2
  sandbox was designed as a hash **plus** a content diff whenever the member checkout is
  reachable (myclickup `work/archive/0016-tools-distribution-channel/plan.md` §5.4, item 5),
  and on the Mac the member checkouts sit beside the channel.

## 4. Hand back

Accepted or declined, and the recipe name if it lands, so the channel's `AGENTS.md` can
quote it.
