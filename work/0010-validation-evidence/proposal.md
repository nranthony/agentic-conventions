# Proposal: `validation/` — a home for measured-behaviour evidence

- Status: Draft
- Author: nranthony + agent
- Date: 2026-08-11
- Origin: a signal-processing repo needed somewhere to put `beat_truth.json` — a
  committed record of measured detector accuracy that a CI gate reads by path. Neither
  `docs/`, `tests/`, nor `work/` was right, which is the tell that a category is missing.

## Summary

Add an opt-in `validation/` tier to the blueprint: a committed, corpus-organised home for
**evidence of measured system behaviour against ground truth**, split into a hand-edited
`expected.*` (what the gate enforces) and a regenerated `measured.*` (what the last run
actually produced).

Scoped deliberately to ground-truth accuracy evidence. Performance benchmarks, golden-output
snapshots and external scan reports are **out** — see *Scope boundary*.

## Motivation

### The gap is real, not a filing preference

The repo that raised this has four provenance tiers and the artifact fits none:

| Tier | What it holds | Why this artifact doesn't fit |
|---|---|---|
| `docs/` | prose canon | a machine-read JSON blob is not prose |
| `tests/` | executable checks | this is an *input* to a check, not a check |
| `docs/adr/` | decisions and their reasoning | a measurement is not a decision |
| `work/` | in-flight items | **`work/` archives on completion; this has a live CI consumer.** Archiving a build dependency is a contradiction |

That last row is the decisive one. `work/`'s exit rule — distil, then archive — is load-bearing
(ADR-0006), and an artifact that a gate reads by path can never satisfy it.

The missing category is **evidence**: a dated record of how the system behaved when measured,
committed on purpose, superseded rather than edited. It is closest in spirit to an ADR — both
are append-ish records of a moment — but ADRs record *what we decided*, and this records
*what we measured*.

### It multiplies

One corpus is a file; four is a tree. The originating repo already has one corpus pinned, a
second with numbers worth pinning, a third arriving with its next work item, and any detector
version bump needs a before/after pair. A convention adopted at one file costs nothing; adopted
at ten it is a migration.

### The hazard the structure has to defend against

If the gate reads the committed record directly, then **regenerating the record moves the
goalposts**, and the diff looks like routine churn. A run that quietly drops two points of
sensitivity produces a green build and a plausible-looking commit. This is the same failure
shape as the dependency-direction defect in ADR-0008's build: not a missing capability, but a
correct-looking artifact whose obvious reading is wrong. Structure has to catch it, because
review reliably does not.

## Proposal

### 1. The directory

```
validation/
├── README.md                # index: what evidence exists, which gate reads what, how to regenerate
└── <corpus>/                # one directory per corpus or dataset
    ├── expected.toml        # hand-edited. The gate's authority. Never machine-written.
    ├── measured.json        # regenerated. The record of the last run. Never hand-edited.
    └── measured.md          # regenerated, same run. The human-readable table.
```

Organised **by corpus**, not by metric or by date — a corpus is the unit a reader asks about
("how do we do on NSTDB?"), and it is also the unit that changes independently.

### 2. The filename encodes authority

Two rules, symmetrical and mechanically checkable:

- **Nothing regenerates `expected.*`.** A regeneration script that writes it is a bug.
- **Nobody hand-edits `measured.*`.** A hand-edit there is falsifying a record.

That is the whole defence against the goalpost hazard. A threshold change becomes a one-line
edit to a small file that cannot hide inside a regenerated blob, and it is a path a reviewer —
or `CODEOWNERS` — can watch. `expected.toml` is small on purpose: tolerances and thresholds,
not a mirror of the measurements.

### 3. Every record carries its provenance

A number is meaningless without what produced it. `measured.json` opens with:

```json
{
  "provenance": {
    "generated": "2026-08-11",
    "commit": "b472aef",
    "command": "python scripts/mitdb_beat_report.py --write",
    "corpus": "MIT-BIH Arrhythmia Database v1.0.0",
    "corpus_digest": "sha256:…"
  },
  "records": { }
}
```

`measured.md` repeats it as a header so the human artifact is self-dating.

`corpus_digest` earns its place: without it, an apparent regression may be a *data* change, and
the two are indistinguishable after the fact. `command` earns its place because the common
end-state for an un-regenerable record is folklore — nobody remembers how to refresh it, so
nobody does, and it silently becomes a claim rather than evidence.

### 4. `validation/README.md` is an index, not a runbook

Three columns: what evidence exists, which gate consumes it, and the exact command that
regenerates it. The *how it works* write-up stays in `docs/` — the tier holds evidence and
points at the prose, exactly as `work/` points at ADRs rather than restating them.

### 5. Where it sits against the other tiers

New row for the blueprint's provenance table:

| The question | Lives in | Shape |
|---|---|---|
| How well does it actually perform, and measured against what? | `validation/<corpus>/` | hand-edited `expected.*` + regenerated `measured.*` |

And the boundaries: `docs/` keeps the harness runbook; `tests/`/CI keeps the gate itself;
`validation/` holds only what the gate reads and what a human reads to check the claim.
When a measured number moves and the threshold is deliberately relaxed, the `expected.*` diff
*is* the record — unless the relaxation is direction-setting (accepting worse accuracy to buy
something else), which is an ADR like any other trade-off.

### 6. Why `validation/` and not `qa/`

`qa/` is the honest, unloaded word. `validation/` is the regulated one: IEC 62304 / ISO 13485
expect *requirement → verification protocol → verification record*, and this tree is already
shaped like the third. The name costs nothing now and saves a rename if a safety-case question
ever resolves toward "this software is an owned control."

**Stated plainly in the ADR:** naming a directory `validation/` makes no compliance claim. It
declines to fight the vocabulary later; it does not assert a process.

### Scope boundary — what this tier does *not* hold

Ground-truth accuracy evidence only. Explicitly excluded, with where they go instead:

- **Golden-output snapshots** → `tests/`. They have an established home beside their consumer
  and no audience beyond the test runner. Nobody audits them to check a claim.
- **Performance / latency benchmarks** → nowhere yet. Environment-dependent, so a committed
  record is frequently noise rather than evidence. The structure would extend cleanly if a
  repo ever needs it; do not ship a tier claiming coverage it has not earned.
- **External reports and scan baselines** → out for now. Different provenance model entirely:
  produced outside the repo, not regenerable from it, so rules 2 and 3 do not apply.

### Implementation path (on acceptance)

1. **ADR-0009** — the decision: the missing category, the expected/measured split, the naming
   rationale plus its non-claim, the scope boundary.
2. **Blueprint** — an "Opt-in — validation evidence" bullet beside the external-tracker one,
   the layout entry, and the provenance-table row.
3. **`templates/validation/`** — `README.md` and one example corpus directory carrying both
   files and a filled provenance block, generic per the templates rule: no real corpus, no
   real numbers presented as defaults.
4. **`just sync-plugin` + `just validate`**, CHANGELOG entry, `plugin.json` version bump —
   this changes what a consumer receives.
5. **AGENTS.md** index line.

This repo will never carry a `validation/` tier itself — it ships no measurable behaviour. The
template is the only artifact here, which is the usual state for the opt-in tiers.

## Open questions

- **Format of `expected.*`.** TOML reads well and is already the pins-file convention here;
  JSON is what a gate parses without a dependency. Pin one in the blueprint for consistency, or
  say only "small, hand-editable, non-generated" and let each repo choose?
- **Enforcement.** The two authority rules are checkable — a CI gate could flag a `measured.*`
  diff whose `provenance.commit` did not change (a hand-edit) or an `expected.*` write from a
  regeneration script. Worth shipping a check, or is `CODEOWNERS` on `validation/*/expected.*`
  enough? Enforcement is the team-ceremony tier; this may not belong in the lean path.
- **Is the committed `.md` companion required or optional?** It is the artifact a collaborator
  reads, which argues required. It is also duplicated data that can drift from the JSON if
  regenerated separately — so the rule may need to be "one command writes both, always."
- **Size ceiling.** A per-record table for a large corpus stops being reviewable somewhere.
  At what size does a record stop belonging in git?
- **Migration cost for the originating repo.** Its gate reads `beat_truth.json` by hardcoded
  path; adopting this renames it and splits it in two. Worth doing at one corpus, but it is a
  code change, not a move.

## Alternatives

- **`tests/baselines/`** — the standard golden-file convention, cheapest, no new top-level
  directory, lives beside its consumer. Rejected because it buries validation evidence inside
  the test tree, where a collaborator auditing an accuracy claim will not look, and because
  the human-readable table is a document rather than a fixture.
- **`docs/validation/`** — has precedent (a generated, test-gated reference already lives under
  `docs/` in the originating repo). Rejected: `docs/` is prose canon, and a machine-read gate
  input sits oddly in it. Keeps the runbook, loses the evidence.
- **`reports/` at root** — the usual name for generated output, and exactly the problem: it
  reads as gitignorable scratch, while these files are committed deliberately.
- **`work/`** — rejected on the exit rule. See *Motivation*.
- **`qa/`** — see §6. A live option if the regulated vocabulary is judged misleading.
- **Gate reads the record directly, no split** — one artifact, no duplication, simplest to
  implement. Rejected: it makes every regeneration a potential silent goalpost move, defended
  only by review discipline, and the whole point of the tier is to make that visible.
- **Do nothing; decide per repo.** Reasonable while there is one file. Rejected because the
  originating repo is already at three corpora and rising, and because the expected/measured
  rule is the kind of thing every repo would otherwise re-derive — badly, and only after being
  bitten.
