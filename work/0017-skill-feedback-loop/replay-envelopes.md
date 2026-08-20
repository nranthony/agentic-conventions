# Replay test (§5): three past incidents written as envelopes, retrospectively

Run 2026-08-20, against the envelope as shipped in `/myconv:report-skill-feedback`
(myconv 0.6.0). The question each time: **would this envelope have made the incident
actionable on arrival, with no reply?** Live traffic already ran the test twice (the
0018 batch and the numerai report, both recorded in `proposal.md`); these are the
three retrospective ones the proposal named.

## 1. `variants/` carried into the payload (work/0003 §3)

```markdown
# Skill feedback: (payload-wide) — installed copy contains variants/ directories

- From: <any consumer> (retrospective)
- Version: myconv 0.x skill:<hash>
- Install mode: plugin
- Invocation: n/a — found by inspecting the installed tree
- Artifact: skill (the shipped payload; the defect is upstream in its generator)
- Broke at: n/a — no instruction fails; the tree carries files no consumer can use
- Frequency: every run
- Symptom: none-fit:unexpected-files
- Verdict: generic
- Risk class: mechanical
- Workaround applied locally: ignored the directories

## Proposed edit
None to the skill text — sync-plugin should exclude variants/ on the way in.
```

**Verdict: holds, with the `none-fit` escape doing the work.** The artifact list
(skill / blueprint / template / ADR) has no "generator" entry on purpose — a consumer
sees shipped text, not our tooling — so a packaging defect arrives as `none-fit` plus
evidence, and triage maps it upstream. Watch for recurring `none-fit:packaging`-shaped
slugs; that is the signal the list needs a new entry, per the skill's own rule.

## 2. Plugin-payload links that escaped (fixed twice; now `check-plugin-links`)

```markdown
# Skill feedback: apply-conventions — relative link resolves to nothing

- From: <any consumer> (retrospective)
- Version: myconv 0.x skill:<hash>
- Install mode: plugin
- Invocation: /myconv:apply-conventions <path>
- Artifact: skill
- Broke at: "Where the shared skills come from" — link `](../docs/adr/...)` targets
  a file outside the installed payload
- Frequency: every run
- Symptom: wrong-path
- Verdict: generic — the payload cannot read the rest of the source repo anywhere
- Risk class: mechanical
- Workaround applied locally: cited the ADR by number instead of following the link
```

**Verdict: holds cleanly.** Symptom + quoted heading + generic verdict is exactly the
mechanical lane; the second occurrence would have been grouped by slug instead of
rediscovered. This incident cost two separate fixes precisely because nothing grouped
the first report with the second.

## 3. The vendored wheel whose version string lied (myclickup work/0011 §4)

**Verdict: correctly out of scope — the envelope rejecting it is the right answer.**
The defective artifact is a *wheel*, not skill text; no `VERSION` sidecar, no heading
to quote, no skill instruction broke. The channel that owns this failure is depot's
publish content-check (built for exactly this incident), and a feedback envelope that
stretched to hold it would be a second, worse copy of that control. A schema is also
judged by what it refuses.

## Outcome

No schema change. One watch-item (recurring `none-fit` slugs as the list-growth
signal — already stated in the skill). The §5 exit condition is met: five envelopes
run — two live, three retrospective — and the schema held or correctly refused each.
