# ADR-0004: Skills replace slash commands as the single procedure slot

- Status: Accepted
- Date: 2026-07-31
- Deciders: nranthony + agent
- Supersedes: [ADR-0002](0002-slash-commands-for-invoked-procedures.md) (the
  `.claude/commands/` slot; the invoke-deliberately principle survives)

## Context

ADR-0002 adopted `.claude/commands/*.md` for human-invoked procedures, forking
"auto-invoke → skill; human-invoke → command." Claude Code has since merged the two
mechanisms: a skill at `.claude/skills/<name>/SKILL.md` creates the same `/name`
invocation, supports the same frontmatter (`description`, `argument-hint`,
`$ARGUMENTS`), and adds what commands lack — supporting files, `allowed-tools`,
`model`, and `disable-model-invocation` for invocation control. Commands are not
deprecated (a removal proposal was closed "not planned"), so this is a choice, not a
forced migration.

Two facts decided it:

- **One slot is simpler to distribute.** Downstream consumers (per-repo vendored
  copies, container runtimes seeding `~/.claude` per instance) already have a skills
  seeding path; a parallel `commands/` channel doubles every vendor/seed/refresh step
  for no capability gain.
- **The ADR-0002 fork is now a frontmatter flag, not a directory choice.** Whether a
  procedure auto-triggers is controlled per-skill, so the directory split no longer
  carries the distinction.

Verified while deciding: `.agents/skills/` (the emerging cross-tool standard the
reference previously pointed at) is **not** read by Claude Code — `.claude/skills/`
is the discovered project slot.

## Decision

**All shared procedures live as skills** at `.claude/skills/<name>/SKILL.md`, with
genericised mirrors in `templates/.claude/skills/`. `/wrap-up` and `/make-plan` are
migrated as-is; `.claude/commands/` is removed from this repo, its templates, and the
reference scaffold's recommended layout.

**Skills keep the default invocation** — both the human (via `/name`) and the model
(by description match) may invoke them. `disable-model-invocation: true` stays
available per-skill for procedures that must never fire on their own, but is not the
default here.

The scaffold's skills slot is corrected to `.claude/skills/` (Claude Code's real
discovery path); `.agents/skills/` is noted as a cross-tool standard to revisit if
Claude Code adopts it.

## Consequences

- One mechanism to document, vendor, seed, and refresh downstream — the distribution
  doc becomes [distributing-skills-downstream.md](../distributing-skills-downstream.md).
- Skills can grow supporting files (templates, scripts) without changing slots.
- Heavyweight procedures are now model-invocable by default; their descriptions must
  say when they apply ("complex, multi-issue threads only") so auto-triggering stays
  rare and sensible. If one misfires in practice, set `disable-model-invocation: true`
  on that skill.
- Repos that vendored the command form keep working (commands aren't deprecated) and
  migrate by moving `foo.md` → `skills/foo/SKILL.md` + `name:` frontmatter.

## Alternatives considered

- **Keep commands (the 2026-07-30 position):** rejected a day later — correct that
  nothing forces migration, but it left two slots doing one job and doubled the
  downstream distribution surface.
- **Skills with `disable-model-invocation: true` everywhere:** rejected — the owner
  wants both human and model able to run these procedures; per-skill opt-out remains.
- **`.agents/skills/` as the slot:** rejected — Claude Code does not read it today.
