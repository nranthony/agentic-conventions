# Proposal: the environment names the venv — cross-repo rollout

- Status: Accepted → ADR-0017
- Author: nranthony + agent (from the sandbox tool's `work/0008-venv-per-environment`
  handoff, 2026-09-11)

## Summary

A sandbox exports `UV_PROJECT_ENVIRONMENT=.venv-sandbox`, and a host leaves it unset and
uses `.venv`. Repos never hard-code a venv path. They ignore `.venv*/` and the `.local`
pair, and they pin a tracked `.python-version`. The rule and its rationale are in
[ADR-0017](../../docs/adr/0017-the-environment-names-the-venv.md). This item tracks the
rollout until both sandboxes are live and the old venvs are gone.

## Motivation

See ADR-0017 §Context. In short: one checkout is seen by a host and a sandbox, both
default to `.venv`, and uv rebuilds a venv whose interpreter it can't use, so each side
kept destroying the other's.

## Proposal — rollout

| Where | What | State (2026-09-11) |
|---|---|---|
| sandbox tool (macolima) | Proves the rule in one shell before merging (T0) | **Done.** Held: 309 tests green on `.venv-sandbox`, host-slot venv byte-identical |
| agentic-conventions | ADR-0017, blueprint section, `templates/.gitignore`, audit flags; myconv 0.9.0 | This release |
| myclickup | `.gitignore` `.venv*/` + `.local` pair; `.python-version` 3.12; README and `docs/downstream.md` prose | Local commit, owner pushes |
| paperbridge | `.gitignore` `.venv*/` + `.local` pair; `.python-version` 3.12; its gitignored `settings.local.json` venv-path allow rules reported to the owner | Local commit, owner pushes |
| depot | `.gitignore` `.local` pair + `.venv*/`; `AGENTS.md` Publishing names both cache paths and the pre-switch hazard | Local commit |
| sandbox tool (macolima) | Compose variable, deletion-hook carve-out, notice section, `verify-sandbox` assertion | Its work/0008; live on each profile's recreate |
| windows-ai-sandbox | The same set | Carried across by the owner, from macolima |
| every profile (T5) | `echo $UV_PROJECT_ENVIRONMENT` → `.venv-sandbox`; each member's gate green on it | Waits on the "variable is live" signal |
| Phase F | Delete the old container-built venvs (`myclickup/.venv`, `home = /usr/bin`) | Human step, after a clean run period |

**Exit rule:** archive this item when T5 has passed on every sandbox profile and Phase F
is done or explicitly declined. Anything durable learned during the rollout amends
ADR-0017 by superseding it, never by editing it.

## Open questions

- paperbridge's sandbox venv can't be built offline: its wheels aren't in the uv cache
  (the first miss is `certifi==2026.2.25`). Either an egress window warms the cache, or
  paperbridge stays a host-side gate. That's the owner's call.
  **Answered for now, 2026-09-15:** the cache is warm, and paperbridge's gate runs fully
  offline in the macolima container (146 passed, 7 skipped —
  `reply-to-macolima-work-0008-t5.md`). A cold cache reopens it.

## Alternatives

See ADR-0017 §Alternatives considered.
