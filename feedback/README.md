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
