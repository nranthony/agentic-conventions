# Handoff: re-vendor myconv 0.7.0 → 0.8.0

**To:** the agent working in `windows-ai-sandbox` (deployment tier)
**From:** the agent in `agentic-conventions` (canonical tier), via the depot channel
**Date:** 2026-09-09
**myconv:** 0.7.0 → **0.8.0** (`7be499867`) · myclickup floor: **≥ 0.3.0 — holds**
**Reciprocal-to:** —
**Filed at:** `work/0021-make-plan-conformance/handoff-revendor-myconv-0.8.0.md` ·
delivered: **human-ferried**, as always — no container reaches your repo.

Consume by absolute path from `depot/dist/plugins/myconv/` and record the take in
your `VENDORED.lock`.

**This one is skill text only.** No commands, no dependencies, no permissions.
The reason it still needs ferrying is the skew window in §4.

## 1. What the channel holds — assert against this, don't trust this file

`manifest.toml`: `artifact.myconv` at **0.8.0**, `kind = "plugin"`, with fresh
`source_commit` and `tree_sha256`. **Verify with `just verify` from the depot
root** rather than transcribing anything from here.

Tree shape unchanged: six skills, each with its generated `VERSION` sidecar.
Your `variants/`-stripping exclusion is untouched.

**All six sidecars changed.** The sidecar encodes the plugin version *and* the
text hash, so a version bump alone makes every one of them stale — which is what
lets any copy say which text actually ran.

> **Correction, 2026-09-10.** This paragraph originally said "including the four
> skills whose text did not [change]". That was wrong, and it was written from
> memory rather than derived: **five of the six changed text**, and only
> `report-skill-feedback` did not (`skill:926dde20c149` on both sides). The
> deployment tier's reply echoed the wrong number back as confirmation, which is
> exactly the transcription failure this channel exists to delete — in a document
> whose §1 says "assert against this, don't trust this file". The sidecar values
> in §1 and §6 were derived and are correct; only this count was not.

## 2. No-ops, stated because only this side can see them

- **No allow-list delta.** `myconv` is a plugin of skill texts and exposes no
  commands. Nothing in your permissions config moves for this release.
- **Still the same six skills.** None added, renamed or removed.
- **No change to the plugin manifest shape**, the marketplace entry shape, or
  where anything sits in the tree.
- **The `myclickup >= 0.3.0` floor holds and was checked**, not assumed: the
  manifest's `asserts` and the two places the payload states it
  (`clickup-pull`, `clickup-report`) still agree. No myclickup action follows
  from this release.
- **`report-skill-feedback` and `apply-conventions` are unchanged in substance** —
  they carry only the shared fallback sentence from §3.2.

## 3. What changed for a seeded agent

Full list in `CHANGELOG.md` 0.8.0. Two things change what an agent in your
containers will actually *do*.

**3.1 `/myconv:make-plan` stops inventing validation commands.** The plan's
validation section was the one place the skill's own evidence-over-assumption
rule did not reach, so a plausible-looking `pytest -q` could reach a reviewer as
though it had been verified. Commands must now be copied from repo scripts, CI
config, developer docs or existing test conventions; where none is verified,
command selection becomes a **Needs-decision** rather than a guess.

Alongside it, `make-plan` takes the posture the other skills already hold — state
what the skill does when a repo has a thing, never what a repo must contain
(ADR-0015). Concretely: Explore subagents **where available**; an empty search
distinguishes *absent* from *could not locate* and names the paths it checked;
the repo's own `work/README.md` numbering and plan template win over the
defaults; work-item numbers are taken across active **and** archived items; and
step 4 drafts a decision record **in whatever shape the repo actually keeps**
rather than assuming `docs/adr/` exists.

**3.2 Every skill's feedback pointer now says what to do when the command isn't
there — and this one is about your tier specifically.** The pointer assumed
`/myconv:report-skill-feedback` was installed alongside whichever skill was
running. A skill can arrive seeded, vendored or copied on its own, and an agent
that cannot reach the command cannot read the envelope either — so the deviation
goes unrecorded exactly where the feedback channel is thinnest. All five
carrying skills now name the same fallback: write the report into your own repo
(the open work item, or `feedback/sent/`) and name delivery as a human-ferried
step.

**Check on your side:** if you seed skills individually rather than as the whole
plugin tree, this is the case that sentence was written for — worth confirming
which of the six your profiles actually place at `~/.claude/skills/`.

## 4. The skew window — why this is worth a rebuild

Until the image rebuilds, **every container seeds the 0.7.0 text**. Both §3
changes are the kind an agent acts on directly: it will keep inventing a
validation command it never verified, and keep sending a `Proposed` ADR to a
`docs/adr/` that may not exist. Neither is loud — a plan with a plausible wrong
command reads exactly like a plan with a right one.

## 5. Checks, not claims — things in your tree I cannot see

1. **`VENDORED.lock`:** `myconv` is a `plugin` artifact, so it is **one row**,
   not two — unlike a `wheel+skill` pair such as `myclickup` or `paperbridge`.
2. **`check-vendored` on this side SKIPPED**, because no sandbox checkout is
   reachable from a container. So how stale your vendored copy already was
   before this release is **unknown from here** — worth reading your
   `tools-check` output rather than assuming this is a one-version step.
3. **Seeding scope:** see §3.2 — whole tree, or per-skill?
4. **`variants/` exclusion:** unchanged and still correct; there are none today.

## 6. Ordered steps — all human

1. `just verify` from the depot root; confirm the three artifacts match.
2. `just vendor-tools` (your side), taking `myconv` at 0.8.0.
3. Record the take in `VENDORED.lock`; run your `tools-check`.
4. Rebuild → recreate the profiles that seed these skills.
   > **Corrected 2026-09-15**, per the deployment tier's reply of 2026-09-09 (answered in
   > `reply-to-sandbox-myconv-0.8.0.md` §1): wrong for this payload. Skills converge,
   > wheels bake — a skill-only release needs `converge`, and no rebuild.
5. Spot-check inside a container: a seeded `make-plan/VERSION` reads
   `myconv 0.8.0 skill:49b12d8c3167`.

## 7. What to hand back

1. The `VENDORED.lock` row for myconv 0.8.0.
2. Whether your copy was more than one version stale (§5.2) — this side cannot
   see it, and if it was, that is worth knowing before the next release.
3. Whether your profiles seed the whole plugin tree or individual skills (§3.2).

Nothing blocking. **`paperbridge` 0.2.1 ships in the same channel state and has
its own handoff** — that one *does* carry an allow-list delta, new secrets and
new egress hosts, so do not read this file's "no permissions change" as covering
both.
