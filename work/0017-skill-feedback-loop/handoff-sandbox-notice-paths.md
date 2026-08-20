# Handoff → `windows-ai-sandbox`: the managed notice names a host-only script

- From: `agentic-conventions`, work/0017 (2026-08-20), carrying a consumer report from
  the `numerai` repo (2026-08-19)
- Status: **human-ferried, not yet delivered** — the deployment tier lives on the host
  and no container can reach it; this tracked original is the record.
- Asks for: one edit to the generated sandbox-notice block, plus (optionally) adopting
  a content rule its generator can hold going forward. No behaviour change to the
  sandbox itself.

## The defect

The user-global notice the sandbox injects (`~/.claude/CLAUDE.md`, inside the
`BEGIN/END sandbox-notice` markers) says, under "No dependency installs":

> stop and ask the human to install it in the interactive shell (or via
> `scripts/with-egress.sh`)

`scripts/with-egress.sh` is a host-side script in `windows-ai-sandbox`'s own checkout.
Inside every repo the notice ships into, that path is repo-relative and resolves to
nothing — a dead instruction, and one that drifts silently the moment the host tooling
is renamed. The consumer's audit found it only by resolving paths *inside* the managed
markers, which the ownership rule ("humans and agents never edit inside the markers")
had implicitly discouraged anyone from reading.

## The ask

**Drop the parenthetical, or mark it explicitly host-side.** The human step is
complete as "stop and ask the human"; if the notice wants to keep the hint for the
human's benefit, phrase it so no agent can read it as a path — e.g. "(the human has a
host-side egress wrapper for this)".

**Optionally, adopt the rule the blueprint now carries** (conventions repo,
`reference/agentic_native_repo_scaffold.md`, environment-notice content rule 4), so the
generator enforces it rather than the next audit catching it: *name the ask, not the
host-side mechanism* — everything a notice names must resolve in the environment where
the reading agent stands. Absolute in-sandbox paths (`/usr/lib/wsl/lib/nvidia-smi`),
service hostnames (`postgres:5432`), and the repo's own files pass; paths that resolve
only in the sandbox tool's checkout do not.

## What this deliberately does not ask for

- **No change to what is denied or allowed.** The deny-list, the egress allowlist, and
  the install policy are untouched — only how one human step is worded.
- **No edit from our side.** The block is generated and the markers say so; this is
  precisely the "report upstream, don't edit in place" lane the blueprint now names.
- **No change to `myclickup/AGENTS.md`'s hand-maintained mirror.** Checked 2026-08-20:
  it does not repeat the `with-egress` reference, so the defect is confined to the
  generated block.

## Delivery

Human-ferried, like everything touching the deployment tier. Delivered when the
sandbox regenerates the notice without the host-only path; this file then records the
outcome and the 0017 folder archives with the rest of the item.
