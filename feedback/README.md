# feedback/ — inbound reports about the skills this repo owns

Tracked on purpose (ADR-0016). `inbox/` is the gitignored doorbell for paste-in material
and handoffs; this is the record.

```
feedback/            awaiting triage
feedback/archive/    triaged — disposition below
feedback/sent/       copies this repo filed to other repos
```

**Ownership decides destination.** This repo owns the five `myconv` skills. A tool that
ships its own vendored skill owns that one — `manifest.toml` in the channel names the
`source_repo` for every artifact. A report filed where the text cannot be edited is a
report nobody can action.

**Archived, never deleted** (ADR-0012's rule, second surface). A *rejected* report is the
one recurrence-counting most needs, and the CHANGELOG structurally only records reports
that became changes.

## The ledger

One line per report. Grep the `symptom` column before triaging anything: three reports of
one friction are a signal, one is an anecdote — and the envelope has promised that since
0.6.0 without anything being able to check it.

| date | from | skill | symptom | risk | disposition |
|---|---|---|---|---|---|
| 2026-08-25 | legal | clickup-pull | `assumed-repo-shape` | direction-setting | **applied** — ADR-0014; triage widened it from 2 instructions to 7 fields + the re-pull path |
| 2026-08-25 | depot | report-skill-feedback | `wrong-path` | direction-setting | **applied** — ADR-0016 (this record's own routing fix) |
| 2026-09-08 | ikigai | make-plan | `assumed-repo-shape` | mechanical | **applied** — §4 now follows §2's ladder: ADR dir → the repo's own log in its own format → `plan.md`, labelled. Class confirmed mechanical (it follows from ADR-0015); no new record needed. Shipped in the same 0.8.0 batch as the collated make-plan revision |
| 2026-09-15 | pipeline | clickup-pull | `unclear-step` | mechanical | **applied** — `## Pull` opens with a live queue-discovery block for a call with no task ID. Class confirmed mechanical: it applies preflight item 6 to the one read that escaped it. Reworded, not pasted — the report scoped discovery to `[work_sync].queue`, but the queue is scope × status (ADR-0008 §6), so the bound is `queue` → `scope` → the pinned workspace, named either way; its closing cross-reference to a triage gate was dropped, since that gate is not decided (row below). CLI surface verified against myclickup 0.7.0 source, not assumed. The advertised `argument-hint` still says a task ID is required — widening it is a surface change, deliberately left out of a mechanical fix. Shipped in 0.10.0 |
| 2026-09-15 | pipeline | clickup-pull | `none-fit:no-triage-gate` | direction-setting | **presented, awaiting the owner's decision — not applied** (ADR-0013 §4: a triager presents, the human signs). All three claims verified against the shipped text. Proposal, evidence and assessment in `work/0024-clickup-pull-triage-gate/proposal.md`; ADR-0019 reserved for it, written only if accepted. Class **confirmed**, not split: the "already pulled?" search looks mechanical on its own, and carving it out would be the downward reclassification §3 forbids. Symptom is new, but this is the second direction-setting report on this skill with the same root — the board's claim outranking the repo's state (the first became ADR-0014) |
