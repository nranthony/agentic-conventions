# Skill feedback: clickup-pull — no step for finding the agent-ready queue, so the one read that picks the task can come from the cache

- From: pipeline (2026-09-15)
- Version: myconv 0.9.0 skill:7fae74312f6e
- Install mode: vendored container copy (seeded at `~/.claude/skills/myconv/` in the agent home)
- Invocation: none yet. The skill was read ahead of `/myconv:clickup-pull <task-id>`, to confirm that pulls are live reads and not the sync snapshot.
- Artifact: skill
- Broke at: missing:queue-discovery (nearest text: "## Preflight — stop, don't improvise", item 6)
- Frequency: every run where the caller has no task ID in hand ("pull what's Ready for Agent")
- Symptom: unclear-step
- Verdict: conditional on the repo not pinning `[work_sync].queue`. The skill's arguments take a task ID, and every read after that is correctly `--live`: `task`, `comments`, the blocker gate. But the step that *chooses* which tasks to pull is not in the skill. The `.myclickup.toml` template carries a commented `queue = "Space/Folder/List"` key that the skill never reads. In `myclickup` 0.7.0, `query` and `tasks` are cache-first, so an agent finding the queue with `myclickup query --status "Ready for Agent"` gets the last `sync` snapshot unless it adds `--live` itself. Preflight item 6 ("Every read takes an explicit `--live` … or `--cached`") covers this in principle, but it sits under preflight, not at a discovery step. This repo had synced minutes earlier, so a cached discovery would have looked authoritative.
- Risk class: mechanical. It follows from preflight item 6 and the skill's own stance that a cached status is "the snapshot this gate distrusts".
- Workaround applied locally: the queue was found with `myclickup query --status "Ready for Agent" --brief --live --workspace <pinned id>`, validated case-insensitively.

## Proposed edit
At the top of "## Pull", before the `myclickup task <id> --json --live` block, add:

> **No task ID given?** Find the queue live, never from the cache: a synced snapshot
> shows the board as it was, and the status is exactly what goes stale. Scope it to
> `[work_sync].queue` when pinned; otherwise search the pinned workspace and say that
> no queue was pinned:
>
>     myclickup tasks --list "<queue path>" --status "<agent_ready>" --brief --live
>     myclickup query --status "<agent_ready>" --brief --live      # no queue pinned
>
> An empty result is not an empty queue until the status name is confirmed as
> defined (`tasks` reports this; for `query`, check `statuses --list` per list).
> Present what matched and pull one task ID at a time. Each still goes through
> the triage gate and the live `task` / `comments` reads below.
