# Skill feedback: report-skill-feedback — step 2 routes every report to the conventions repo, including reports about skills it does not own

- From: depot (the channel root) (2026-08-25)
- Version: `myconv 0.6.0 skill:3f9920b10f96` — read from
  `plugins/myconv/skills/report-skill-feedback/VERSION`; the `dist/` sidecar in the
  channel carries the identical string, so payload and published copy agree.
- Install mode: neither plugin nor vendored — the canonical in-repo text was read
  directly at `agentic-conventions/.claude/skills/report-skill-feedback/SKILL.md`.
  The plugin payload copy is byte-identical (`diff` clean), so the defect is in both.
- Invocation: not invoked as a slash command. The skill text was read and followed by
  hand to file this report, which is how the defect surfaced — step 2 named a
  destination that was wrong for the report being written at the time.
- Artifact: skill
- Broke at: `## Where the report goes`, step 2 — quoted verbatim:
  > 2. **Copy it to the conventions repo's `inbox/`** as
  >    `<your-repo>-<skill>-<YYYY-MM-DD>-<slug>.md`.
- Frequency: every run
- Symptom: wrong-path
- Verdict: **generic** — it misroutes for any skill the conventions repo does not own,
  which is not a hypothetical set. Evidence, all from this channel's own record:
  `manifest.toml` declares `[artifact.myclickup]` with `kind = "wheel+skill"` and
  `source_repo = "myclickup"`; that skill's source is `myclickup/packaging/sandbox/SKILL.md`
  and it ships as half a pair under myclickup ADR-0006. So a sixth skill is in
  circulation whose owning repo is not the conventions repo, and step 2 sends its
  feedback to a repo that cannot act on it. The instruction is unconditional — no
  repo-shape fact gates it — so every reporter follows it into the same wrong inbox.
- Risk class: **direction-setting**
  The reporter's first instinct here was `mechanical` (a wrong path is the canonical
  mechanical case). Revised upward on reading ADR-0013 again: §1 states the transport
  as "copies it to **this** repo's `inbox/`" and §4 defines triage as "an agent session
  in **this** repo, working the `inbox/` in batch". Both are written destination-singular.
  Routing by owner turns one inbox into N and splits the triage role across repos, which
  is a change to what ADR-0013 decided, not a correction inside it. Per the skill's own
  tie-breaker — "when unsure, say direction-setting" — it goes to the ADR lane.
- Workaround applied locally: gave myclickup the missing doorbell rather than filing
  into the wrong repo — added `inbox/` to its `.gitignore` with a comment citing
  ADR-0013, created the directory, and added one `Where things live` entry to its
  `AGENTS.md` naming both uses and the triage split. Uncommitted at the time of
  writing. Consumer skill text was not patched (ADR-0013 §6).

## Proposed edit

Under `## Where the report goes`, replace step 2:

```markdown
2. **Copy it to the owning repo's `inbox/`** as
   `<your-repo>-<skill>-<YYYY-MM-DD>-<slug>.md`. The owner is the repo the skill
   ships *from*, not the repo it ran in: the `myconv` skills belong to the
   conventions repo, and a tool's own vendored skill belongs to that tool's repo.
   When a channel is in play, its `manifest.toml` names the `source_repo` for every
   shipped artifact — read it rather than guessing. The inbox is a gitignored
   doorbell: the copy there gets promoted or deleted, never tracked. If the owning
   repo has no `inbox/`, say so in the report and fall back to step 3.
```

Precedent for the fallback shape, if it helps triage: myclickup's own `/handoff`
skill already routes this way — "copy the file into the consumer's `inbox/` if it
has one, else into its `work/` item if one is already tracking the change"
(`myclickup/.claude/skills/handoff/SKILL.md`, step 5). The gap that produced this
report is that the else-branch there requires a work item *already tracking the
change*, and unsolicited feedback arrives with no work item by definition.

## Consequences the triager should weigh, not decide from this report alone

1. **ADR-0013 needs an amending or superseding record if this is accepted.** §1 and §4
   both read destination-singular; ADRs here are append-only, so this is a new record,
   not an edit to 0013.
2. **Triage becomes per-owner.** Each owning repo triages its own inbox. That is
   arguably already true — a repo that cannot act on a report should not be holding
   it — but it is currently unstated, and the "one triage pass, one inbox" phrasing
   in §4 is what makes it look otherwise.
3. **The blueprint question is separate and should stay separate.** Whether every
   member repo gets an `inbox/` by default is a scaffold change (`reference/` mentions
   `inbox/` nowhere today). This report does not propose that, and it should not be
   bundled: routing by owner is correct even if only two repos ever have an inbox.
