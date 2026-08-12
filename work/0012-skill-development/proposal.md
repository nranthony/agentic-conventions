# Proposal: develop the myconv skills against the wider skill ecosystem

- Status: Draft
- Author: agent (Fable 5) + nanthony
- Opened: 2026-08-12, split out of work/0011 (the skill audit) — the audit's
  mechanical fixes stayed there; this item is the "larger thread": deliberate skill
  development informed by what the community ships.

## Summary

Sharpen the five myconv skills so they coexist deliberately with community skill
libraries (obra/superpowers first among them): differentiate by description rather
than name, declare entry points in AGENTS.md, and graft the best community content
into our skills instead of adopting theirs wholesale. One action was pulled forward
into work/0011 and is NOT in scope here: `disable-model-invocation: true` on
clickup-report (decided 2026-08-12).

## Motivation

The 2026-08-12 ecosystem survey (below) found no literal name collisions but a real
*trigger* collision surface: model-invoked skill selection matches on descriptions,
with no documented tie-break. If a superpowers-class library is ever installed
alongside myconv, its `writing-plans` and `finishing-a-development-branch` compete
directly with `make-plan` and `wrap-up` for the same moments in a session. The owner
also wants to expand the library database to other collections and reuse mature
community content where it saves time.

## Proposal (candidate work, roughly ordered)

1. **Sharpen every skill description to name its concrete artifacts.** The docs'
   recommended defense: a description that says `work/NNNN-slug/` and
   `AGENTS.md`/`docs/adr/`/`CHANGELOG` lets the model discriminate against
   near-twins. Do this for make-plan and wrap-up first (the contested pair).
2. **Declare entry points in AGENTS.md** (template and this repo): state that
   `myconv:make-plan` is the planning entry point and `myconv:wrap-up` the
   end-of-thread procedure for repos on these conventions. User/repo instructions
   outrank skill-description matching — superpowers' own bootstrap skill concedes
   this — so this is the cheap, deterministic fix.
3. **Graft, don't adopt, `writing-plans` content** (MIT — keep the copyright notice
   for any substantial copied portion). The parts worth taking into make-plan:
   file-structure-first mapping (map the target file layout before writing tasks)
   and task right-sizing (2–5 minute tasks with exact paths, code, and a
   verification step each). The parts to leave: its flat
   `docs/superpowers/plans/YYYY-MM-DD-*.md` artifact (ours is the work-item
   lifecycle), its mandatory TDD/worktree/subagent-execution chain.
4. **Decide the coexistence posture for superpowers itself**: install alongside (and
   rely on 1–2 above), or stay standalone. Also evaluate
   `superpowers-developing-for-claude-code` (bundles 42+ official Claude Code doc
   files as a skill) as a maintenance aid for this repo regardless of posture.
5. **Plugin granularity for collaborators**: consumers cannot mute individual skills
   of an installed plugin (`skillOverrides` doesn't apply to plugins — all or
   nothing per plugin). When collaborators arrive, consider splitting the ClickUp
   pair into a second plugin (`myclickup-sync`?) so a consumer can take the
   conventions without the tracker coupling. Direction-setting → would need an ADR.
6. **Expand the library watchlist** (see survey): revisit travisvn's index and the
   bulk aggregators periodically; adopt individual skills case-by-case with the
   license rules below.
7. **Worked-example skills, reconsidered post-prune** (folded in from
   `work/0001-example-skills/proposal.md`, 2026-08-12). The idea: ship
   auto-trigger-first examples for adopters — `write-an-adr` (recognise a
   direction-setting decision and record it) and `bootstrap-nested-package` (write
   the two-line `CLAUDE.md` stub beside a new nested `AGENTS.md`) — so an adopter
   copies a working `description:` trigger instead of writing one from scratch,
   which is the part people get wrong. What changed: their original landing slot,
   `templates/.claude/skills/`, no longer exists (work/0011 WP7 pruned it — the
   embedded skill copies were the phantom-skill bug). So if wanted, they ship
   *inside the plugin* as real namespaced skills, or as reference prose showing a
   worked `SKILL.md` rather than a copyable file. Decide which here — including
   "neither", since two more model-invoked skills widen the trigger-collision
   surface this item exists to narrow. The original's selection test is worth
   keeping either way: a procedure earns a skill only if the agent should reach for
   it unprompted, it recurs, and its trigger is sharp; a one-line always-on rule
   belongs in `AGENTS.md`.

## Open questions

- Does sharpening descriptions measurably change model routing? (Testable: install
  superpowers in a scratch profile, run planning prompts, observe which skill fires.)
- Should wrap-up absorb any of `finishing-a-development-branch`'s git-integration
  steps (merge/PR menu, worktree cleanup), or stay documentation-only?
- Timing of the ClickUp-pair split vs. the CLI-first rewrite (work/0011 WP8.1) —
  one restructure or two?

## Alternatives

- **Adopt `writing-plans` outright, retire make-plan**: rejected — it doesn't model
  the work-item lifecycle (proposal → spec → plan → notes, ClickUp front-matter),
  presumes its own brainstorm→plan→subagent chain, and imposes TDD/worktree defaults
  we don't want repo-wide.
- **Rename make-plan/wrap-up to avoid ambiguity**: rejected — no literal collisions
  exist, plugin namespacing already disambiguates invocation, and renaming breaks
  muscle memory; descriptions are the actual collision surface.
- **Upstream wrap-up into superpowers**: off the table — its README states it does
  not generally accept new-skill contributions and requires cross-agent portability.

---

## Appendix A — ecosystem survey (2026-08-12, via webfetch; sources inline)

### obra/superpowers

- MIT (© 2025 Jesse Vincent), plugin `superpowers` v6.2.0; company-backed (Prime
  Radiant, commercial support offered). https://github.com/obra/superpowers
- 15 skills: brainstorming, dispatching-parallel-agents, executing-plans,
  finishing-a-development-branch, receiving-code-review, requesting-code-review,
  subagent-driven-development, systematic-debugging, test-driven-development,
  using-git-worktrees, using-superpowers, verification-before-completion,
  writing-plans, writing-skills.
- Overlap with make-plan: `brainstorming` (Socratic spec elicitation →
  `docs/superpowers/specs/`), `writing-plans` (the planner; "assume the engineer
  has zero context"; plan location overridable by user preference),
  `executing-plans`/`subagent-driven-development` (execution — which make-plan
  deliberately does not do).
- Overlap with wrap-up: weak. `finishing-a-development-branch` is git integration
  (tests green → merge/PR/keep/discard menu → worktree cleanup), NOT provenance.
  `verification-before-completion` is an evidence gate. No journaling/retrospective
  skill; that lives in a separate MCP plugin, `private-journal-mcp`.
- Distribution: Anthropic's official plugin marketplace
  (`/plugin install superpowers@claude-plugins-official`) and the author's own
  (`obra/superpowers-marketplace`). Ships for ~10 agent runtimes from one repo.
  Installs a SessionStart hook injecting `using-superpowers`.
- Does not generally accept skill contributions; updates must work across all
  supported agents.

### Other libraries

| Library | Notes |
|---|---|
| anthropics/skills (official) | 17 skills (docx/pdf/pptx/xlsx, mcp-builder, skill-creator, frontend-design, webapp-testing, …) + the Agent Skills spec. Mostly Apache-2.0; the four document skills are source-available, NOT redistributable. |
| obra/superpowers-marketplace | Curated: superpowers, elements-of-style, superpowers-developing-for-claude-code (42+ official doc files as a skill), private-journal-mcp. |
| obra/superpowers-lab | Experimental superpowers skills. |
| travisvn/awesome-claude-skills (~14.6k★) | Main curated index; community section still thin (Trail of Bits security skills, Expo, shadcn/ui, playwright, get-shit-done, …). |
| jeremylongshore/claude-code-plugins-plus-skills (~2.6k★) | Bulk aggregator, claims 431 plugins / 2,754 skills. Quality varies; generic names certainly exist in bulk — irrelevant under plugin namespacing. |
| alirezarezvani/claude-skills | ~36 role skills; `handoff` (session handoff + redaction linter) is the closest thing to wrap-up in trigger timing, but outputs a handoff note, not repo docs. |

Popularity indexes: claudeskills.info, awesomeclaude.ai.

### Collision mechanics (docs.claude.com: skills page, plugins-reference)

- Plugin skills are namespaced `plugin:skill`; they cannot conflict with each other
  or with repo/user-level skills. Only the *bare* `/name` shorthand is contended
  (first-come). Override precedence exists only between non-plugin levels:
  enterprise > personal > project; any of them overrides a bundled skill of the
  same name.
- Model invocation: all skill descriptions sit in context (combined
  description+when_to_use truncated at 1,536 chars); the model picks by relevance;
  no tie-break documented. Remedy per docs: strengthen the description, or enforce
  with hooks.
- `disable-model-invocation: true`: removes the description from context entirely
  (also excluded from subagent preloading and, since v2.1.196, from scheduled-task
  prompts). Complement: `user-invocable: false`.
- `skillOverrides` in settings lets a consumer mute skills — but NOT plugin skills;
  plugins are all-or-nothing via `/plugin`. (Drives proposal item 5.)

### Name-collision check

make-plan, wrap-up, apply-conventions, clickup-pull, clickup-report: no hits in
superpowers, anthropics/skills, or the awesome index. Near-misses: superpowers
commands `/brainstorm`, `/write-plan`, `/execute-plan`; trigger-space overlap from
`finishing-a-development-branch`. No clash with bundled Claude Code skills
(/code-review, /run, /verify, …).

### Licensing rules for reuse

- superpowers: MIT — fork/modify/redistribute inside this MIT plugin; retain
  copyright notice + license text for substantial copied portions.
- anthropics/skills: mostly Apache-2.0 — MIT-compatible; keep attribution and the
  patent-grant notice in its own file rather than blending; NEVER redistribute the
  four source-available document skills.
- alirezarezvani/claude-skills, wshobson/agents, davila7/claude-code-templates: MIT.

## Appendix B — session notes (2026-08-12)

- Live observation that motivated the description work: this session simultaneously
  carried `make-plan` (repo-local, current), `myconv:make-plan` (seeded, stale
  vintage), and a directory-scoped phantom from the payload templates — three
  variants, two contents. The structural fix (one home per role) is work/0011 WP7;
  the *routing* fix (descriptions, entry-point declarations) is this item.
- The stale-seed episode also showed version stamping only works if the version
  actually bumps — "0.1.0 — unreleased" on every vintage defeats it. Bump
  discipline adopted in work/0011 WP7.5.
- wrap-up is the differentiated asset: nothing in the ecosystem reconciles
  AGENTS.md + ADRs + CHANGELOG + work-item archival. Invest there; don't chase
  parity with community planners.
