# Notes — 0005 plugin distribution

## 2026-08-10 — sandbox agent review round

The `windows-ai-sandbox` agent reviewed [sandbox-handoff.md](sandbox-handoff.md) and verified
the mechanism in-container (claude 2.1.223) rather than from the write-up: built the `myconv`
shape under a throwaway `HOME`, confirmed `probeconv@skills-dir` loads at user scope with
nested skills inventoried, ~8 tokens always-on. Design confirmed; four corrections.

### Accepted in full

1. **Blocking — `reset-skills` backup shadowing.** `profile.sh` writes backups to
   `claude-home/skills/<name>.bak.<stamp>`, inside the scanned directory. For a plugin that is
   a same-name collision and the *backup* wins, so every refresh after the first silently runs
   the previous `myconv`. Fix is theirs (`scripts/profile.sh`, relocate backups outside the
   scan root); handoff now leads with it as step 0.
2. **Vendored location → `sandbox_templates/skills/myconv/`.** Their `ensure_state` and
   `reset-skills` loops `cp -R` each subdirectory verbatim and are shape-agnostic, so the
   plugin needs zero `profile.sh` changes there. Revision 1's
   `sandbox_templates/claude/plugins/` suggestion would have meant new seeding code in a
   security-sensitive file for no gain. Corrected.
3. **Twin removal isn't durable.** Create-only seeding and an argument-less `sync-skills` both
   resurrect `make-plan`/`wrap-up`. Handoff now gives the ordering, gated on
   `claude plugin list` confirming `myconv@skills-dir` before anything is deleted.
4. **The sync script already exists.** `scripts/sync-skills-from-conventions.sh` needs two
   edits (source `plugins/`; gate on `.claude-plugin/plugin.json` rather than a top-level
   `SKILL.md`, which today yields a silent `skipping 'myconv': no SKILL.md`), not a second
   script. Corrected.

### Contributed back

- **The backup problem is already live, not latent.** Verified in this container: the existing
  `audit-sandbox.bak.*` and `web-read.bak.*` declare the *same* `name:` as their live
  counterparts and **both load**, listed by directory name. Loose skills don't shadow, but the
  stale copies are invocable and their descriptions are wrong — `audit-sandbox.bak` still says
  "the staged CLAUDE.md" where the maintained one says "AGENTS.md + ARCHITECTURE.md". So step 0
  fixes a present defect, not just a future one.
- **Content diff over version echo for `myconv`.** Their own argument for `myclickup` — a
  rebuilt 0.1.0 with different bytes is the real drift case — applies here and harder, since
  `just sync-plugin` regenerates the payload without necessarily bumping `version`.
- **Correction 3 step (ii) is free.** Once the sync script sources from `plugins/` (their
  correction 4), it can no longer enumerate the twins. Not a separate task.

### Upstream decisions taken

- **Keep `templates/.claude/skills/{make-plan,wrap-up}`.** Their step (ii) offered "upstream
  drops them" as one option. Declined: `templates/` is the adapt-by-hand surface for *all*
  consumers, and an adopting repo may want committed skills rather than a plugin. The sandbox
  script changes instead.
- **ADR-0007 left untouched.** The `.bak` hazard is a newly-found consequence, not a reversed
  decision, and ADRs here are append-only. Captured as **Rule 4** in
  [docs/distributing-skills-downstream.md](../../docs/distributing-skills-downstream.md)
  instead, generalised for any consumer vendoring a plugin into a scanned skills directory.

### Deferred

- `myclickup` stays a loose skill — agreed, its wheel coupling is stronger than a version field.
- The landing-zone problem (`sandbox_templates/skills/` as home to N upstreams, with a sync
  script named for one) is noted in the handoff. Revisit at three upstreams.

## 2026-08-10 — round 2: seeding became convergence

Inbound: [sandbox-seeding-change.md](sandbox-seeding-change.md). The sandbox declined the fix I
endorsed and took a better one. Rather than relocate backups, their ADR-0005 makes
`sandbox_templates/skills/` the source of truth and each profile's `claude-home/skills/` a
derived cache reconciled on every `up`; backups are not taken at all, because every seeded skill
is a copy of a git-tracked template.

**They were right to go further.** Backup relocation treated the symptom. The disease was
create-only seeding: a copy-if-missing pass can never deliver an *edit*, so a template change
reaches a profile only when someone remembers a refresh command. Their profiles sat 11 days
behind `audit-sandbox` on that axis. My Rule 4 encoded the weaker fix.

### Folded in

- **Handoff → revision 3.** Step 0 becomes "already closed", keeping the probe evidence as the
  motivating trail. Step 3 collapses from a gated resequencing to two actions plus one ordering
  note. `reset-skills` → `up` throughout, including the `myclickup` joint profile pass. Their
  `variants/` strip bug added to step 6.
- **Rule 4 rewritten and generalised** — "don't back up a derived cache; reconcile it, and warn",
  with create-only seeding named as the underlying disease, the two convergence guardrails
  (warn-before-overwrite, scoped prune not mirror) as the safe shape, and backup-outside-the-scan-
  root demoted to a fallback for genuinely non-reproducible copies. The `claude plugin init`
  collision is why a prune must never mirror.
- **`variants/` hazard pushed upstream.** Their sync script strips `variants/` at loose-skill
  depth, which no-ops one level deeper in plugin mode. Zero `variants/` exist today, so nothing
  leaks — but the root cause is ours: `just sync-plugin` copies `templates/` wholesale, so if
  `work/0003-skills-beyond-this-repo/proposal.md` §3 ever ships, claude.ai-only bodies
  ride into every consumer. Noted there, at the source, rather than left to N consumers to strip.

### Their open question — does ADR-0007's rationale need restating?

**No, and ADR-0007 stays untouched.** Their concern is fair — if the record leans on "one unit to
refresh", convergence weakens it. But checking ADR-0007's three forces against what convergence
actually changed:

1. **More than one machine** — untouched. Convergence is intra-sandbox; it does nothing for a
   second host. This was the trigger.
2. **Many repos under one profile** — untouched. That property comes from `~/.claude/skills/`
   being personal scope, not from seeding semantics.
3. **Hand-vendoring had drifted** — *halved*, not removed. There were always two axes:
   repo → template tree (on-demand human sync) and template tree → profile (create-only).
   Convergence closes the second. The first remains, and is now the only one, which is why the
   `vendor-check` content diff matters more than before.

So 2.5 of 3 forces stand, and force 3 was the *evidence that made it urgent*, never the reason
for the design. The three durable benefits they name — namespacing, a version visible in
`claude plugin list`, single-unit inventory via `claude plugin details` — are already in
ADR-0007's Decision and Consequences.

Structurally: ADRs here are append-only, and an ADR is a dated record of a decision *and the
forces as understood then*. Retro-fitting later information into an accepted record is the thing
append-only exists to prevent. A reader who needs the update finds it here and in Rule 4 — which
is where someone asking "how do I distribute this" actually lands. If the decision ever reverses,
that gets its own ADR.
