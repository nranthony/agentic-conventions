# Beads Adoption Plan — Agentic Conventions Repo

**Target:** Upstream Beads (`bd`), Go + Dolt backend — https://github.com/gastownhall/beads
**Strategy:** Implement in the conventions repo first → pilot one repo → roll out repo-by-repo → evaluate per repo before promoting.
**Non-goals (for now):** Gas Town orchestration, Wasteland federation, replacing human-facing trackers.

---

## 0. Key References

| Resource | Link |
|---|---|
| Canonical repo (Dolt-based upstream) | https://github.com/gastownhall/beads |
| README / quick start | https://github.com/gastownhall/beads/blob/main/README.md |
| FAQ (multi-agent, Dolt modes, isolation) | https://github.com/gastownhall/beads/blob/main/docs/FAQ.md |
| Dolt backend guide | `docs/` in repo — connection flags, backup, embedded↔server migration |
| Community tools (viewers, editor plugins) | `docs/COMMUNITY_TOOLS.md` in repo |
| Related/adjacent projects | `docs/related-projects.md` in repo |
| Origin post (concepts) | https://steve-yegge.medium.com/introducing-beads-a-coding-agent-memory-system-637d7d92514a |
| Best practices post | https://steve-yegge.medium.com/beads-best-practices-2db636b9760c |
| Gas Town context (future layer) | https://yegge.ai/gastown |

> Note: `steveyegge/beads` redirects to / is superseded by `gastownhall/beads`. Always install and upgrade from **gastownhall**.

---

## 1. Architecture Snapshot (what you're adopting)

- **Storage:** Dolt (version-controlled SQL DB) in `.beads/`. Cell-level merge, native branching.
  - **Embedded mode** (default, `bd init`): in-process Dolt, data in `.beads/embeddeddolt/`, single writer. Use this everywhere initially.
  - **Server mode** (`bd init --server`): external `dolt sql-server`, multiple concurrent writers. Adopt only when 2+ agents/humans write simultaneously on one machine.
- **`issues.jsonl` is an export/interchange file, NOT the source of truth or backup** (this changed from the classic SQLite+JSONL design).
- **Sync:** `bd dolt push` / `bd dolt pull` against `refs/dolt/data` on your git remote. Git hooks optional.
- **IDs:** hash-based (`bd-a1b2`) → no merge collisions across agents/branches.
- **Core loop:** `bd create` → dependency graph → `bd ready` → `bd update <id> --claim` → `bd close <id>`.
- **Memory features:** `bd remember "insight"` (persistent project memory), compaction (`bd admin compact`), messaging issue type with threading, graph links (`relates-to`, `duplicates`, `supersedes`, `replies-to`).

---

## 2. Phase 1 — Bootstrap in the Conventions Repo (Day 0–1)

### 2.1 Install (machine-wide, once)

```bash
# macOS/Linux (verify checksums — install script does this)
curl -fsSL https://raw.githubusercontent.com/gastownhall/beads/main/scripts/install.sh | bash
# or: brew install beads   (macOS/Linux)
# or: npm install -g @beads/bd
bd version && bd doctor
```

Pin the installed version in the conventions repo (see 2.3). Upgrade cadence: **weekly**, via `bd upgrade`, followed by `bd doctor --fix`.

### 2.2 Initialize in the conventions repo

```bash
cd ~/repos/agentic-conventions
bd init                      # creates .beads/, updates AGENTS.md, installs agent integrations
bd setup --list              # see supported integrations
bd setup claude              # Claude Code hooks/settings
bd setup codex               # if you use Codex CLI
# other: bd setup cursor | factory | mux ...
```

Set a short prefix immediately (readability across projects):

```bash
# ask your agent, or use bd's prefix change command; convention: 2-3 chars per repo
# e.g. conventions repo → "cv-", so issues read cv-a1b2
```

### 2.3 Add Beads conventions AS conventions (the point of this repo)

Create these files in the conventions repo:

```
agentic-conventions/
├── AGENTS.md                        # bd init updates this; keep the bd block canonical here
├── conventions/
│   ├── beads/
│   │   ├── ADOPTION.md              # this plan
│   │   ├── WORKFLOW.md              # canonical agent workflow (copy block below)
│   │   ├── PREFIXES.md              # registry: repo → prefix (cv-, wk1-, pr1-...)
│   │   └── VERSION.md               # pinned bd version + upgrade log
│   └── decision-records/
│       └── ADR-00XX-adopt-beads.md  # record THIS decision as an ADR
└── .beads/                          # dogfood: track the rollout itself in bd
```

**Canonical AGENTS.md block** (paste into every migrated repo; `bd init` generates similar):

```markdown
## Task tracking (Beads)
This project uses bd (beads) for issue tracking.
- Run `bd prime` at session start for workflow context.
- Use `bd ready --json` to find unblocked work; `bd update <id> --claim` to take it.
- File a bd issue for ANY work expected to take >2 minutes, including work discovered mid-task.
- File bd issues during code reviews instead of inline TODO comments.
- Use `bd remember "insight"` for persistent project memory; do NOT create MEMORY.md files.
- Do NOT use markdown TODO lists or plans/ directories for task tracking.
- Link discovered work with discovered-from; use blocks/parent-child for ordering.
- At session end run "land the plane": sync git state, update/close issues,
  `bd dolt push`, and emit a ready-to-paste prompt for the next session.
```

### 2.4 Dogfood: track the rollout in bd itself

```bash
bd create "Phase 1: bootstrap conventions repo" -t epic -p 1
bd create "Write WORKFLOW.md + PREFIXES.md" -t task -p 1
bd create "ADR: adopt beads (upstream Dolt)" -t task -p 1
bd create "Phase 2: pilot repo migration" -t epic -p 1
bd dep add <phase2-id> <phase1-id>        # phase 2 blocked by phase 1
bd ready --json
```

---

## 3. Coexistence Rules — Beads vs. Existing Structures

Your repos already have folder structures, decision records, and plans. **Beads replaces only the execution-tracking layer.** Division of responsibility:

| Artifact | Keep? | Role after Beads |
|---|---|---|
| `decision-records/` (ADRs) | **Keep** | WHY. Immutable decisions. Beads issues link to ADRs by path/ID in description. |
| Specs / PRDs / design docs | **Keep** | WHAT (future). Planning layer. Decompose into bd epics when work moves to "now". |
| `plans/*.md`, `TODO.md`, task checklists | **Retire** | Migrate open items to bd issues, then delete (git history preserves them). |
| `MEMORY.md` / notes files | **Retire** | Replace with `bd remember`. |
| GitHub Issues / Linear / etc. | **Keep (backlog of record)** | Human-facing backlog + stakeholder view. Pull items into bd epics on activation; cross-link URLs both ways. |
| Inline `// TODO` comments | **Discourage** | Agents file bd issues instead during reviews. |

**Cross-linking convention:** every bd epic description carries `ADR: decision-records/ADR-0012.md` and/or `Spec: docs/specs/foo.md` and/or upstream tracker URL. Every retired plan file gets a final commit message listing the bd IDs it became.

**Backlog hygiene:** keep `bd ready` crisp. Distant "someday" items stay in your existing backlog system; use P4 sparingly for discovered-but-not-urgent. Granularity: one issue per ~2min+ unit of work; not "add import statement" micro-tasks.

---

## 4. Phase 2 — Pilot Repo (Week 1–2)

**Pick:** one active, low-risk **personal** repo (solo, no teammates, frequent agent sessions — maximizes signal, minimizes blast radius).

```bash
cd ~/repos/pilot-repo
bd init && bd setup claude
# set prefix per PREFIXES.md registry, e.g. pl-
```

**Migration of existing state (agent-driven — don't do this by hand):**
1. Agent reads `plans/`, `TODO.md`, open checklist items.
2. Agent creates bd issues with correct types (epic/task/bug/chore), priorities (0–4), and deps; adds `discovered-from`/source-file references in descriptions.
3. Agent cross-links relevant ADRs into epic descriptions.
4. Delete the migrated markdown plans in the same PR (recoverable via git history).
5. Commit `.beads/` per the sync mode you choose (below).

**Sync choice for the pilot:**
- Solo, one machine → default; just commit and `bd dolt push` as part of land-the-plane.
- Multi-machine → `bd dolt push` / `bd dolt pull` via git remote (`refs/dolt/data`).
- Work repo where you can't commit tooling files → `bd init --stealth` (local-only, no git ops) — Beads without touching the shared repo.

**Daily rhythm (the self-improving loop):**
1. Session start: `bd prime`, then agent runs `bd ready --json` and claims top item.
2. During work: agent files issues for discovered work (>2 min rule).
3. Session end: **land the plane** — update/close issues, `bd dolt push`, emit next-session prompt.
4. Keep sessions short; Beads is the working memory between them.

---

## 5. Phase 3 — Repo-by-Repo Rollout (Weeks 2–8)

**Order:** personal-solo → personal-multi-machine → work-solo (stealth if needed) → work-with-teammates.

**Per-repo checklist (copy into a bd epic per repo):**
- [ ] Register prefix in `conventions/beads/PREFIXES.md`
- [ ] `bd init` (+ `--stealth` if repo policy requires) + `bd setup <agent>`
- [ ] Paste canonical AGENTS.md block from conventions repo
- [ ] Agent-migrate open plans/TODOs → bd issues; delete source files
- [ ] Cross-link ADRs/specs into epics
- [ ] Choose sync mode; verify `bd dolt push`/`pull` round-trip (if applicable)
- [ ] 1 week of daily use → run evaluation (Section 7)
- [ ] Decision: promote / hold / rollback (record outcome in the rollout epic)

**When a teammate joins a repo:**
- They install bd (same pinned version), `bd dolt pull`.
- Everyone claims atomically: `bd update <id> --claim --assignee <name>` — claim-before-work is the anti-conflict rule.
- Cell-level merge handles most concurrent edits; escalate to server mode (`bd init --server` migration via `bd backup`) only if you see real write contention on one machine.
- Same-machine multi-project: `export BEADS_DOLT_SHARED_SERVER=1` (one Dolt process serves all projects, DBs stay isolated).

**Cross-repo work:** databases are isolated by design — issues can't reference other repos' issues. Options: (a) init bd in a parent directory spanning both projects for genuinely shared workstreams, or (b) keep per-repo DBs and coordinate via the conventions-repo rollout epics + cross-links in descriptions. Prefer (b) until it hurts.

---

## 6. Maintenance & Hygiene

```bash
bd upgrade                      # weekly
bd doctor --fix                 # after upgrades & after messy merges
bd admin compact --dry-run --all    # preview memory decay
bd admin compact --days 90          # summarize old closed issues (context-window savings)
cd .beads/dolt && dolt gc           # storage GC (server-mode layout)
bd backup                       # before mode migrations / risky upgrades
```

- Log every upgrade + notable behavior change in `conventions/beads/VERSION.md`.
- Expect occasional sync conflicts on rebases — ask the agent to run `bd sync` / clean up; this is normal and improving fast upstream.
- Windows AV false positives: see `docs/ANTIVIRUS.md`; always verify release checksums.

---

## 7. Evaluation Criteria (per repo, before promoting)

Score after ~1 week of real use; record in the repo's rollout epic:

1. **Orientation time** — can a fresh session answer "what's next?" from `bd ready` alone, without you re-briefing? (primary success metric)
2. **Discovered-work capture** — are >2min discoveries landing as issues instead of evaporating?
3. **Plan drift** — zero new markdown plan files created?
4. **Friction** — daemon/Dolt startup issues, sync conflicts per week, doctor interventions.
5. **Token/cost** — is `bd ready` output staying small (backlog hygiene holding)?
6. **Teammate onboarding** (where applicable) — time from install to first claimed+closed issue.

**Rollback per repo:** `bd backup`, export final `issues.jsonl`, convert open issues back to your tracker of choice, remove `.beads/` + AGENTS.md block. Git history retains everything.

---

## 8. Later Horizons (out of scope now, informs conventions today)

- **Claude Code native Tasks** — use for in-session scratch coordination; bd remains cross-session/cross-agent memory. Complementary layers.
- **Messaging/mail** — bd's message issue type (threading, mail delegation) is the on-ramp to multi-agent coordination without extra infra.
- **Gas Town / Gas City / Wasteland** — orchestration and federation layers built on the same Beads ledger; your per-repo bd discipline is the prerequisite skill. https://yegge.ai/gastown
- **Enterprise bridge pattern:** human tracker = backlog of record → bd = per-team execution ledger → messaging/federation = inter-team bus. Keep conventions written so this mapping stays clean.
