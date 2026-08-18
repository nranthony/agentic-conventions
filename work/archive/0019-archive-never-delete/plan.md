# Plan: work items archive on exit — withdraw the "or delete it" option

- Status: Done (2026-08-18) — archived; rationale distilled to
  [ADR-0012](../../docs/adr/0012-work-items-archive-never-delete.md)
- Author: agent (Opus 5) + nanthony
- Opened: 2026-08-18, from a direct owner ask — the apply-conventions skill should
  never suggest deleting a work item, only archiving.
- Decides: the exit-rule change is recorded in
  [ADR-0012](../../docs/adr/0012-work-items-archive-never-delete.md). Pre-decided work,
  so this item opens as a plan rather than a proposal.

## Why this is an item and not just an edit

The edit itself is small — seven lines across five files. What makes it worth a number is
that the lines are not the source. Every "or delete it" in the shipped blueprint traces to
one sentence in the proposals-are-work-items decision (ADR-0006):

> Pure-implementation items with nothing durable may still be deleted.

Editing the payload without withdrawing that sentence would leave the repo's own decision
record contradicting the rule it ships, and the next agent to read ADR-0006 would put the
option back. So the ADR leads and the edits follow.

## Scope

In scope: the `work/NNNN-slug/` exit rule, everywhere the blueprint states it, plus the two
shared skills that restate it. Out of scope: every other deletion rule in the repo — the
`inbox/` doorbell is still read-then-deleted, `work/plans/` is still gitignored scratch,
and the ClickUp write path still has no delete verb at all.

## Work packages

Edit the root originals only; the `plugins/myconv/` copies are generated
(`just sync-plugin`).

| # | File | Line (pre-edit) | What it says now |
|---|---|---|---|
| **W1** | `docs/adr/0012-...md` | new | the decision itself |
| **W2** | `docs/adr/0006-proposals-are-work-items.md` | header | add an "Amended by" pointer — append-only, no rewrite |
| **W3** | `reference/agentic_native_repo_scaffold.md` | 87 | the `work/` exit rule — "or delete it if nothing durable remains" |
| **W4** | `reference/agentic_native_repo_scaffold.md` | 319 | "How to move forward" — "archive or delete it" |
| **W5** | `reference/agentic_native_repo_scaffold.md` | 375 | the embedded `work/README.md` template block — the phrase again |
| **W6** | `templates/work/README.md` | 31 | "Pure-implementation items … may be deleted instead" |
| **W7** | `templates/AGENTS.md` | 50 | "then archive or delete it" |
| **W8** | `.claude/skills/make-plan/SKILL.md` | 41 | "the folder is archived or deleted" |
| **W9** | `.claude/skills/wrap-up/SKILL.md` | 83 | "or delete it if nothing durable remains" |
| **W10** | `work/README.md` | 25 | this repo's own copy, written from the same template |
| **W11** | — | — | `just sync-plugin`, `just check`, CHANGELOG entry, version bump in both manifests |

W8 and W9 sit outside the apply-conventions payload. They are in anyway: leaving the
planning and wrap-up skills saying "archive or delete" while the blueprint says
"archive" is the two-voices drift that `work/0014` already exists to complain about.

`apply-conventions/SKILL.md` itself needs no edit — it never mentions deletion. It
inherits the suggestion entirely through its generated `reference/` and `templates/`
payload, which is why W3–W7 are the whole fix for the skill the ask names.

## Exit rule

Distil is already done — the rationale lives in ADR-0012, not here. This item archives
once W1–W11 are complete, `just check` passes, and the CHANGELOG carries a consumer-facing
line. Nothing durable will remain in this folder; under the old rule that made it a
delete candidate, which is a fair illustration of what the rule now forbids.

## Progress

- [x] W1 — ADR-0012 written, Accepted
- [x] W2 — ADR-0006 "Amended by" pointer; it stays Accepted
- [x] W3–W5 — reference scaffold, all three sites
- [x] W6–W7 — templates
- [x] W8–W9 — shared skills (make-plan, wrap-up)
- [x] W10 — this repo's `work/README.md`, citing ADR-0012
- [x] W11 — `just sync-plugin`; `just check` passes (check-vendored SKIPPED — no sandbox
      checkout on this machine, which is the host-side tier, not a fault); CHANGELOG 0.5.0
      section; both manifests bumped 0.4.0 → 0.5.0

`apply-conventions/SKILL.md` needed no edit, as predicted: it states no exit rule of its
own and inherits the wording through its generated payload.

## Not done here

Two downstream steps are deliberately outside this item, and neither is an agent action
from inside a container:

- **Publishing 0.5.0 to the channel** (`just publish` → `depot/`). The version is bumped
  and the CHANGELOG section still reads "unreleased"; publishing is what makes it true.
- **Re-vendoring into `windows-ai-sandbox`.** That tier lives on the host and no container
  can reach it; it takes what it takes by absolute path and records it in its own lock file.

## Out of band

`CHANGELOG.md` heads its 0.4.0 section "unreleased", but the channel published myconv
0.4.0 (twice — the second time for provenance only). Flagged, not fixed here: it is a
separate correction and this item should not carry it.
