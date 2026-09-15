# 0023 — the sandbox notice leaves the repo (myconv 0.10.0)

Opened at execution time rather than as a proposal: the decision was taken in the
sandbox tool's repo (**macolima ADR-0015**, Accepted 2026-09-14) and arrived here as a
handoff, `depot/inbox/0011-handoff-depot-notice.md`. The question for this repo was not
whether, but which sites carry the old instruction.

## The problem

The blueprint told a repo edited inside a restricted sandbox to carry a machine-managed
`BEGIN/END sandbox-notice` block at the very top of its root `AGENTS.md`. Both sandboxes
now write their notice into each agent's **global home** instead — `~/.claude/CLAUDE.md`
and `~/.gemini/config/rules/sandbox-notice.md`, on every `up`/`converge` — and never into
a repo. The per-repo route died of two measured failures: a repo's agent may not edit
inside the markers, so a stale block was unfixable from inside; and two sandboxes writing
different markers into one slot stacked a second block rather than replacing the first.
Rationale and the full decision: [ADR-0018](../../docs/adr/0018-the-sandbox-notice-lives-in-the-agent-home.md).

## What changed

| File | Change |
|---|---|
| `docs/adr/0018-…` | new record, adopting macolima ADR-0015 on the blueprint side |
| `reference/…scaffold.md` tier list | "sandboxed execution" stops being an opt-in with a file attached: the tier now says a sandboxed repo adds **nothing** |
| `reference/…scaffold.md` advice-vs-enforcement | the deny-list's paired advice comes from the sandbox, in the agent's home; the repo writes nothing for it |
| `reference/…scaffold.md` "Environment notice" | retitled and rewritten: where the notice actually lives, then the block shape as something to **recognise**, with the neutral marker wording and a note that the two legacy spellings are migration-only |
| same section, ownership rules | replaced by what to do with a block you *find*: stale on sight, reported, removed by the owner; read inside the markers, never edit inside them, never add one |
| same section, content rule 4 | still "name the ask, not the host-side mechanism"; gains the consequence that a notice in an agent's home has no repo around it, so no repo-relative path resolves there. (The lead-in also said "Three content rules" above a list of four — fixed while here.) |
| `reference/…scaffold.md` brownfield phase 2 | a managed block is itself a finding, not a read-only fixture to resolve paths inside |
| `plugins/myconv/skills/apply-conventions/SKILL.md` step 1 | same change — authored in place in the plugin tree, per the justfile |
| `templates/AGENTS.md` | its comment invited a sandbox tool to inject a block "here"; now says no notice belongs in a repo, and what to do with one you meet |
| `CHANGELOG.md`, `plugin.json`, `marketplace.json` | 0.10.0 |

**`templates/AGENTS.md` seeded no block** — item 5 of the ask, confirmed. What it did
carry was the invitation quoted above, which is why it still needed an edit.

## Two judgement calls worth stating

- **The blueprint does not name macolima's scripts.** The handoff's table gives the
  concrete mechanism (`NOTICE-IN-REPO` in `workspace-scan.py`, removal with
  `sync-agent-notice.sh --strip`), and ADR-0018 records it, because an ADR is read by
  people who have those repos. The blueprint and the skill ship to arbitrary consumers,
  where the blueprint's own content rule 4 applies — never name a host-side mechanism
  that does not resolve where the reader stands — so they say "reported for removal by
  whoever owns the sandbox" and stop.
- **The section stays, rather than being deleted.** Blocks exist in the field; an agent
  meeting one with no guidance will either trust it or repair it, and both are wrong.

## A correction to the handoff

Its §3 says "Nothing in the depot's own repos carries a block." Both members did carry
one, and dropped it by hand on 2026-09-14 — myclickup `55c7999`, paperbridge `ccb1b65`,
each a single `AGENTS.md` commit citing macolima ADR-0015. `agentic-conventions` and the
channel itself never carried one. So the statement is true today and was not true when it
was written; no work was re-done on the strength of it, and none is outstanding.

## Exit rule

Archive once the owner has re-vendored myconv 0.10.0 into both sandboxes' seeded
`~/.claude/skills/myconv/` and the reply below has been ferried to macolima. Nothing else
here is load-bearing: the durable rationale is in ADR-0018 and what a consumer receives
is in `CHANGELOG.md` 0.10.0.

Hand-back: [reply-to-macolima-work-0011.md](reply-to-macolima-work-0011.md).
