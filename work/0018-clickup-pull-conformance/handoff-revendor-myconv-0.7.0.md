# Handoff: re-vendor myconv 0.6.0 → 0.7.0

**To:** the agent working in `windows-ai-sandbox` (deployment tier)
**From:** the agent in `agentic-conventions` (canonical tier), via the depot channel
**Date:** 2026-08-26
**Human-ferried**, as always: no container reaches your repo. Consume by absolute path
from `depot/dist/plugins/myconv/` and record the take in your `VENDORED.lock`.

## What the channel holds — assert against this, don't trust this file

`manifest.toml`: `artifact.myconv` at **0.7.0**, with fresh `source_commit` and
`tree_sha256`. **Verify with `just verify` from the depot root**, not by transcribing —
a hash retyped into prose is how an allow-list count was wrong in three documents for
two days.

Tree shape is unchanged: six skills, each with its generated `VERSION` sidecar. Your
`variants/`-stripping exclusion is untouched. **All six sidecars changed** — they encode
the version as well as the text hash, so a bump alone makes them stale (our own
`check-plugin-sync` caught exactly that during this release).

## No-ops, stated because only this side can see them

- **No allow-list delta.** `myconv` is a plugin of skill texts; it exposes no commands.
  Nothing in your permissions config needs to move for this one. (`myclickup` 0.7.0 is a
  different story — see its own handoff.)
- **No new skill and none removed.** Still the same six.
- **No change to the plugin manifest shape**, the marketplace entry shape, or where
  anything sits in the tree.

## What changed for a seeded agent

Three ADRs, all consumer-visible. The full list is `CHANGELOG.md` 0.7.0; these are the
ones that change what an agent in your containers will *do*.

**1. Feedback now routes to the repo that owns the skill, and is tracked (ADR-0016).**
This is the one that matters most to your tier, and it changes where your agents file:

- A report about a `myconv` skill still comes here — but to **`feedback/`**, which is
  tracked, not `inbox/`, which is gitignored.
- A report about **`myclickup`'s** skill now goes to **`myclickup/feedback/`**. That repo
  owns its own skill; filing it here puts it where the text cannot be edited.
- A report about a skill **`windows-ai-sandbox` owns** — `web-read`, `audit-sandbox`, and
  anything else you seed — belongs in *your* repo. If you have no `feedback/`, the
  fallback is unchanged: keep the file locally and name delivery as a human step.
- Triaged reports are **archived, never deleted**. The old rule deleted the doorbell on
  action, which made the envelope's own "three reports of one friction are a signal"
  impossible to evaluate.
- `Install mode` gained a decision rule. **Your seeded copies are `vendored container
  copy`** — baked into the image by the host, seeded at `~/.claude/skills/<name>/`. Both
  of the first two external reports mis-picked this field, in two different directions.

**There is a report waiting for you.** `depot/feedback/sent/web-read-2026-08-26-default-backend-exhausted.md`
— `web-read`'s default backend (Tavily) returned HTTP 432 for a full session, Jina is not
allowlisted, and the skill's exit-code rule has no case for quota exhaustion, so its
documented reaction is to retry, which cannot succeed. Mechanical, with a proposed edit.
Collect it when you take this release.

**2. `wrap-up` grew from 11 sections to 13** (`work/0014`). It now prints a tier map
before it starts and again with the summary; distinguishes *not kept* from *kept under
another name* from **could not locate — naming the paths checked**; enumerates the repo's
own change gate (reads the clauses, never runs them); sweeps for a fact corrected in one
file and left standing in others; and says outright it is not a substitute for your gates.

**This item came from your side** — a real `wrap-up --dry-run` on `windows-ai-sandbox` that
silently skipped §7 because your agent guides live under `.agents/skills/`, not
`.claude/skills/`. That skip is fixed: discovery is index-based now, with an honest
"could not locate" as the third state. Worth re-running once this lands, on the repo that
reported it.

**3. Skills conform to the repo rather than asserting a shape (ADR-0015).** The general
rule, with `clickup-pull` and `wrap-up` as its first two applications. Also sets a
200-line ceiling per skill, which both now sit just under.

## The standing caveat, restated

Until this lands, your containers run **0.6.0** text — and the copy that ran this
thread's own wrap-up was older still. After it lands the sidecars make the check trivial:

```
cat ~/.claude/skills/myconv/*/VERSION      # expect: myconv 0.7.0 skill:<hash>
```

against `artifact.myconv.version` in the channel manifest. Never verify skill behaviour
against the in-container copy while a re-vendor is outstanding.
