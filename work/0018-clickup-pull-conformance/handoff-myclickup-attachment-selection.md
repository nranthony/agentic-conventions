# Handoff → `myclickup`: a selector for `attachments --download`

- From: `agentic-conventions`, work/0018 (2026-08-18)
- Status: **not yet delivered** — tracked original only. See "Delivery" at the end.
- Asks for: one flag, plus two fields in an existing report. No behaviour change to
  what is already decided.

## The ask

**A repeatable `--only <attachment-id>` on `attachments`.** Today `--download` is
all-or-nothing per task, so a caller that has already decided *which* attachments it
wants cannot express that decision — it fetches everything or nothing.

    myclickup attachments <task-id> --download --dir <path> --only <att-id> --only <att-id>

Unknown IDs should fail loudly rather than fetch nothing quietly; an ID not on the task
is a caller bug, not an empty result.

## Why the CLI and not the caller

The consumer is the `/clickup-pull` skill (work/0018, group B). It wants to pull small
text-ish attachments into a work item and leave large binaries on the board. It can
already *make* that decision — `attachments <id> --json` returns the raw objects, so
`mimetype`, `size`, `extension` and `version` are all in hand.

What it cannot do is act on it. The only workaround is to download everything to a temp
directory and delete what it did not want, which:

- spends the bandwidth and the proxy round-trip that the size cap exists to avoid — the
  cost is at the fetch, so pruning afterwards saves nothing that matters;
- makes the skill delete files it just wrote, in an environment where recursive removal
  is hook-blocked by design.

So the split lands where the CLI-first rewrite (work/archive/0013) put it: **which files**
is policy and stays in the skill; **the fetch** is mechanism and belongs here.

## What this deliberately does not ask for

The attachment-download decision (`docs/adr/0010-attachment-downloads.md`) settled four
things this handoff leaves exactly as they are:

- **No `--url`, still.** `--only` takes an attachment ID, resolved against the payload of
  the task you named. It reaches no URL the task did not already return, so it does not
  reopen the fetch-primitive question rule 5 closed.
- **No `--force`, and none wanted.** Rule 4's never-overwrite is the behaviour the
  consumer asked for — the skill wants diff-and-ask, not clobber. That deferral should
  stay deferred.
- **Host restriction and token handling unchanged.** `--only` narrows a set; it does not
  touch which hosts are reachable or when the `Authorization` header is sent.
- **No filtering predicates.** Not `--max-bytes`, not `--mimetype`. Those would move the
  caller's policy into the CLI, and the next caller's policy would differ.

## Second, smaller ask: make `skipped` diffable

`_download_attachments` already returns a `skipped` list for files that exist. For the
consumer to report *why* a skip happened — same file, or a replaced one — those entries
need the on-disk size alongside the attachment's `size` and `version`. Two fields; no
new request, no new behaviour.

## What is blocked on this, and what is not

Not blocked: the reporting half of work/0018 (recording what was left behind, provenance
lines, surfacing `skipped`). That lands without any CLI change.

Blocked: the download gate itself — and on a second thing outside both repos. The Vault's
attachment host, `t90141509251.p.clickup-attachments.com`, is **not on the sandbox egress
allowlist**, which that ADR's own consequences section predicted ("a workspace missing
from it fails at the proxy — loudly"). So the gate needs this flag *and* a human step in
`windows-ai-sandbox`. Shipping `--only` alone is still useful; it just is not exercisable
from a container until the allowlist entry exists.

## Delivery

`myclickup` has no `inbox/`, and no `.gitignore` entry that would keep one untracked —
and that repo had active sessions committing during the exchange this came from. Dropping
an untracked directory into it invites an ephemeral file being committed by someone who
did not write it.

So this original is tracked here, and delivery is a deliberate step: either add
`inbox/` + a gitignore line there first, or paste this into a `myclickup` work item
directly. Not done unilaterally.
