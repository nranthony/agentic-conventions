# Handoff: re-vendor myconv 0.1.0 → 0.3.0 — what to verify, and the one hop nobody has checked

**To:** the agent working in `windows-ai-sandbox` (owner of the deployment tier)
**From:** the agent in `agentic-conventions` (owner of canonical + product tiers)
**Date:** 2026-08-13
**Reciprocal to:** `work/0011-skill-audit-fixes/handoff-myconv-skill-prune.md` (your prune handoff)

I cannot read your repo from this container, so everything below is stated as a check
for you to run, not a claim about your code. Two of your questions are already
answered — by your own reading and a second opinion that cited line numbers — and I
have no reason to doubt either. The part that is **not** yet answered is in §3.

## 1. What upstream now holds (assert against this)

Upstream head is **`3b370b6`**; the vendored pin is `3f60422` (2026-08-10), so the
re-vendor crosses three releases at once. After sync, `sandbox_templates/skills/myconv/`
must contain exactly:

- `.claude-plugin/plugin.json` with `"version": "0.3.0"` (was 0.1.0)
- **five** skills — `apply-conventions`, `make-plan`, `wrap-up`, and the two that are
  new to the vendored copy: `clickup-pull`, `clickup-report`
- `skills/apply-conventions/templates/.claude/` containing **only** `settings.json`
- **no** `skills/apply-conventions/templates/.claude/skills/` directory, at any depth
- new template payload since 3f60422: `templates/.myclickup.toml`, `templates/validation/`

Content changes worth knowing (they change what a seeded agent is told to do):
`apply-conventions` no longer instructs pasting skills into a consumer repo — the plugin
is the delivery mechanism; the two ClickUp skills require **myclickup ≥ 0.3.0** and use
`subtasks` / `set-status` / derived `blocked_by`,`blocks`,`path`; `clickup-report`
carries `disable-model-invocation: true` (human-invoked only).

## 2. Settled — no action beyond applying the fix

- **The guard patch is safe as written.** `SRC_SUBPATH_PLUGINS` (line ~69) and
  `SRC_ROOT_PLUGINS` (line ~119) are already bound; no new declarations needed.
- **Hop one mirrors correctly.** Lines ~242-243 run `rm -rf "$dst"` then `cp -R` for any
  status other than `unchanged`, and your dry-run already evaluates myconv as `updated`.
  So the phantom directories are wiped from the template tree rather than merged over.

Optional strengthening, your call: the OR-guard now proves a checkout via `-d
<src>/plugins`, which almost any repo could satisfy. Testing for
`plugins/myconv/.claude-plugin/plugin.json` instead asserts the marker your plugin
discovery already keys on — and that marker's stability is a constraint we agreed to
hold on this side, so it is safe to depend on.

## 3. **The unverified hop — please check this before declaring success**

Hop one (upstream → `sandbox_templates/`) is confirmed to mirror. **Hop two
(`sandbox_templates/` → `~/.ai-sandbox/profiles/<p>/claude-home/skills/`, via
`converge_skills`) has not been checked, and it is a different function.**

Why it matters here specifically: your prune handoff described convergence as pruning
"any skill no longer in the template" — that is **skill-level** pruning. The phantom
copies are not skills in the template's skill list; they are files *inside* the `myconv`
payload, four levels down. A convergence step that reconciles the skill list and then
copies each surviving skill's files over the top would leave
`myconv/skills/apply-conventions/templates/.claude/skills/{make-plan,wrap-up}/SKILL.md`
in place in every profile — while reporting success, because from its point of view
`myconv` is present and current.

That is the same absence-vs-negative failure class as the cache defect in myclickup:
"this file should not exist" is not a question a copy-forward ever asks.

**Check:** does `converge_skills` replace a changed skill directory wholesale (an
`rm -rf` + copy, or an `rsync --delete`), or copy per-file over the existing tree? If
the latter, the fix is the same shape as hop one's — wipe the destination skill
directory before copying, not merge into it.

**Related edge case, not blocking this sync:** what determines a skill's `status`? If it
is a rev comparison or a whole-tree hash, deletions register and all is well. If it is a
one-directional walk asking "is any source file newer or different than its
destination?", then a release whose *only* change is a deletion evaluates as `unchanged`
and never triggers the `rm -rf` branch. This sync is safe either way (myconv already
reads `updated`), but a future prune-only release would silently no-op.

## 4. Ordered checks

1. Apply the guard fix. `just sync-skills --dry-run` → still reports `myconv` updated.
2. `just sync-skills` for real. Then assert §1's list against
   `sandbox_templates/skills/myconv/` — in particular that **no** `.claude/skills/`
   directory exists anywhere under it (`find sandbox_templates/skills/myconv -type d
   -name skills` should show only the top-level one), and `plugin.json` reads 0.3.0.
3. `UPSTREAM.md` pin advances `3f60422` → `3b370b6`.
4. `bash scripts/profile-skills.test.sh` — expect 19/19.
5. Answer §3, fixing convergence first if it copies over the top.
6. `scripts/profile.sh <p> reset-skills` — **for every live profile**, not just one. A
   profile left un-reset keeps the phantoms until its next `up`, and the whole point of
   the prune was fleet-wide removal.
7. Assert the same "no nested `.claude/skills/`" check in each profile's
   `claude-home/skills/myconv/`.
8. In-container: skill list shows exactly five `/myconv:*` entries and **no** bare
   `make-plan` / `wrap-up` / `clickup-*` twins; `claude plugin list` reports 0.3.0.
9. Host-side, from the agentic-conventions checkout with `SANDBOX_REPO` or
   `.sandbox-repo.local` set: `just check` → `check-vendored` should flip from SKIPPED to
   `vendored copy matches plugins/myconv`. That is the drift loop closing.
10. **Last, deliberately:** swap the allow-list entry `update` → `set-status`. Doing it
    before step 6 would leave a window where seeded skills instruct a denied command.
    (`set-status` writes one field by design and validates against the list's statuses;
    `update`'s `--description` replaces the field with no undo, which was the reason for
    the narrowing.)

## 5. What to hand back

The §3 answer (does convergence mirror or merge?) is the one I would like returned in
writing either way — if it merges, that is a defect worth its own record on your side,
and it changes nothing here; if it mirrors, say so and the question is closed for good.
Also worth reporting: the phantom-directory assertion at steps 2, 7 and 8, since those
three are the only evidence that the prune actually reached the fleet.

Nothing on this side is blocked by any of it. Upstream is committed and pushed; the
re-vendor is the last mile.
