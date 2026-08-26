# Skill feedback: clickup-pull — verbatim description + title-derived slug collide with a repo that forbids identifying detail in committed work items

- From: legal (2026-08-25)
- Version: `myconv 0.6.0 skill:b8b615924456`
- Install mode: plugin (seeded into the container's agent home at
  `~/.claude/skills/myconv/`; `.claude-plugin/` present)
- Invocation: `/myconv:clickup-pull` (no argument), then a pull of one task by ID
- Artifact: skill
- Broke at: `## Create the item` — two instructions under that heading:
  "**Slug from the task title, cleaned.**" and "Then a `## From ClickUp` section
  quoting the task description **verbatim**"
- Frequency: every run (in this repo, for any task concerning a real matter)
- Symptom: `assumed-repo-shape`
- Verdict: conditional on a repo whose own rules forbid identifying detail in
  committed files. Evidence: this repo's `AGENTS.md` and an accepted ADR state that
  work items are committed and must carry no real party names, matter numbers, sums
  or dates, and that a matter is referred to by its tracker task rather than by its
  facts. Both of the skill's instructions above write exactly that detail into a
  committed file: the tracker's task titles are named after real people, and the
  description carries the substance of the matter. The skill assumes committed
  work items are unrestricted prose. Repos without a confidentiality rule are
  unaffected, which is why this is conditional rather than generic.
- Risk class: direction-setting — the edit adds a carve-out to what the pull
  *decides* gets committed. Claimed upward deliberately; triage may reclassify.
- Workaround applied locally: pulled the task, then de-identified both fields. The
  slug uses a generic descriptor instead of the title; the `## From ClickUp` section
  is a labelled de-identified restatement rather than a verbatim quote, with a line
  saying the verbatim text and the parties live in the tracker task. Front-matter
  `ClickUp:` id and URL are unchanged — the pointer is the whole point, and it leaks
  nothing on its own. Nothing was written to the tracker.

## Proposed edit

Under `## Create the item`, after the "Slug from the task title, cleaned." bullet:

> - **Check the repo's own confidentiality rules before writing either the slug or the
>   description.** A work item is committed. If the repo's `AGENTS.md` or an ADR
>   restricts what may enter tracked files — client or party names, matter numbers,
>   sums, dates — those rules win over both instructions above, exactly as they do in
>   `apply-conventions`. Derive the slug from the *kind* of work rather than the title,
>   and replace the verbatim `## From ClickUp` quote with a de-identified restatement
>   that is **labelled as one**, naming the tracker task as the home of the verbatim
>   text. Keep the `ClickUp:` id and URL: a pointer identifies nothing by itself, and
>   without it the restatement cannot be checked. Say in the handoff that the pull was
>   de-identified and why — a silent de-identification reads as a lossy pull.

And under `## Pull`, a one-line pointer so the constraint is seen before the read:

> Read the repo's confidentiality rules first if it has any — they change what the
> created item may contain (see `## Create the item`).

Note for triage: this overlaps the tracker/`work/` split (the sync-asymmetry ADR).
That ADR already says document text does not cross into the tracker; this is the
mirror case — matter text crossing *out* of the tracker into a committed file — and
it does not appear to be covered.
