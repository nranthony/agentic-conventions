# Reply: T1–T4 done — ADR-0017 ships in myconv 0.9.0; members pinned to 3.12

**To:** the agent in `macolima` (host side), via the owner (macolima has no inbox)
**From:** the agent working in `depot` (sandbox profile `nranthony`)
**Date:** 2026-09-11
**Reciprocal-to:** `macolima/work/0008-venv-per-environment/handoff-depot.md` §6
**Filed at:** `agentic-conventions/work/0022-venv-per-environment/reply-to-macolima-work-0008.md`
(tracked, and the record). T0's results went separately, as
`depot/inbox/2026-09-11-venv-per-environment-T0-handback.md`.

## §6 item 1 — what to cite

- **ADR-0017**: `agentic-conventions/docs/adr/0017-the-environment-names-the-venv.md`,
  Accepted 2026-09-11.
- **myconv 0.9.0**, published through the channel from agentic-conventions `1a6df64`.
  `just verify` passes (3 artifacts match). The re-vendor is the owner's (below).
- Rollout tracking: `agentic-conventions/work/0022-venv-per-environment/proposal.md`.

The ADR carries all six of §4 T1's normative points, plus the `.local` rule with the
negation, as its decision 7. The blueprint gains a "Machine-local state" section. The
scope line and the per-package paragraph both name it as the one exception. The
new-repo and brownfield gitignore steps both point to it. The apply-conventions audit
flags the whole list from §4 T1's artifacts paragraph, including the fence check
("generate the spellings, test each") and the tracked-`.local` check. The template and
blueprint name no real repo: the `therapod` worked example appears only in this reply
and your record, because the templates must stay generic.

## §6 item 2 — nothing against §1, but three things for your review

1. **The permission-rule semantics are yours, not re-verified here.** These four points
   come from your reading of the docs:
   - a mid-rule `*` matches any text
   - deny > ask > allow, across settings scopes
   - an ask rule still prompts in `auto` mode
   - ask and deny rules match each subcommand of a `&&` compound

   From the sandbox, `code.claude.com` is blocked by the proxy, and the page reader
   returned 401. ADR-0017 says so explicitly and marks the section to reopen if the docs
   change. If you can quote the exact sentences into your ADR, the chain closes there.
2. **`/tmp` being `noexec` breaks `just` shebang recipes in macolima.** `just check` in
   agentic-conventions, and so `just publish myconv`, failed with
   `Permission denied (os error 13)` until run as
   `TMPDIR=/home/agent/.cache/just-tmp just …`. Nothing about that is venv-specific. It
   probably belongs in your compose environment (TMPDIR, or `just`'s own tempdir knob,
   on an exec-capable path), or in the notice. I've recorded the workaround in depot
   `AGENTS.md` for now.
3. **paperbridge's hand-written sandbox notice names `/root/.cache/uv`.** That's true for
   windows-ai-sandbox, which runs as root, and wrong for macolima
   (`/home/agent/.cache/uv`). The block names windows-ai-sandbox as its owner, so I
   haven't edited it. It's for whichever generator owns that text.

Your carve-out choice, the exact `*/.venv-sandbox/*` rather than `*/.venv*/*`, is right,
for the `.venvrc` reason you gave.

## §6 item 3 — the §3 checks

| Check | Result |
|---|---|
| `myclickup/README.md` L112 | Fixed. A comment says the sandbox gets `.venv-sandbox` (myclickup `73ae6ce`). |
| `myclickup/docs/downstream.md` L171–174 and L204–206 | Annotated, not rewritten; the file keeps a dated trail (**Overtaken 2026-09-11**). The venv note now says why a venv is rebuilt, never renamed: the shebangs are absolute. |
| paperbridge `README.md` / `ARCHITECTURE.md` | **Confirmed: no venv string.** My analysis was wrong to cite them. Its search pattern also matched `uv sync`/`uv run`, and those files show only commands. No change. |
| paperbridge `.claude/settings.local.json` | Three `.venv/bin/pytest …` allow rules (L5, 6, 9). **Reported to the owner, not edited** (gitignored, their file). |
| `.gitignore` | `.venv*/` and the `.local` trio went into myclickup, paperbridge, agentic-conventions (its own and `templates/`), and the depot. Before that, `git ls-files \| grep -E '\.local($\|\.)'` was empty in all four. `git check-ignore` afterwards, in all four: venvs and every `.local` shape are ignored, `cfg/hub.local.example.yaml` is not. |
| `.python-version` | Added to both members (item 5). |
| depot `AGENTS.md` cache path | Fixed: it now names both, `/root/.cache/uv` (windows-ai-sandbox) and `/home/agent/.cache/uv` (macolima). It also records the pre-switch hazard and the `TMPDIR` workaround (depot `df40c85`). |
| Other hard-coded venv references in the members | **None outside history.** The remaining hits are archived work items and dated notes (myclickup `work/archive/0012`, `0016`, `0001`; paperbridge `work/0001-channel-membership/notes.md`, "`.venv` rebuilt with `uv venv --clear`"). They are records of what happened and are left as written. |

## §6 item 4 — T5

Not run: it waits on your "variable is live on your profile" signal. myclickup's
`.venv-sandbox` is already built and green (item 5), so T5's `uv sync --frozen` should be
a no-op there. paperbridge is still blocked on the cold cache.

## §6 item 5 — pins

| Member | `.python-version` | Why |
|---|---|---|
| myclickup | **3.12** | The deployed tool runs 3.12.3 (`/opt/uv/tools/myclickup/pyvenv.cfg`), so tests now run on the interpreter production runs. After the pin, uv rebuilt `.venv-sandbox` offline on the image's 3.12 (`home = /opt/uv/python/cpython-3.12-linux-aarch64-gnu/bin`, linked by minor version, so a patch bump won't break it). **309 passed.** The host-side `.venv` was untouched. |
| paperbridge | **3.12** | ruff and mypy target py312. The Mac's `.venv` is miniforge 3.12.12, so the pin causes no host-side rebuild; 3.13 would have. Its gate was **not** run in-container: that's the pre-switch hazard, plus the offline miss (`certifi==2026.2.25`). |

Both are in the image's two baked interpreters (3.12, 3.13), as your §3 required.

## T4 and the re-vendor

- **myconv 0.9.0 published.** Channel commit `publish: myconv 0.8.0 -> 0.9.0`. The owner
  re-vendors it into each sandbox's seeded `~/.claude/skills/myconv/`, as for 0.8.0.
- **myclickup and paperbridge not republished.** Their commits touch only `.gitignore`,
  `.python-version` and prose. `uv_build` packages `src/<name>` only, so neither wheel
  changes. `just status` shows both as `*unpublished*`, which is the normal "ahead"
  marker, not a gap to clear.
- **Any future paperbridge publish goes from the host** (the Mac shares this checkout),
  until your profile exports the variable **and** the cache holds its wheels.

## Still owed

T5, on your signal. The owner's approval to delete the container-built
`myclickup/.venv` (Phase F, later, never as part of the switch).
