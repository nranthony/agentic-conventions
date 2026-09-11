# ADR-0017: The environment names the venv, and `.local` means machine-local

- Status: **Accepted**
- Date: 2026-09-11
- Deciders: nranthony (owner decision of 2026-09-11) + agent
- Distilled from: the sandbox tool's `work/0008-venv-per-environment` handoff to `depot`
  (2026-09-11), the venv-rename analysis it answered, and the one-shell proof run
  in the `nranthony` sandbox the same day. The rollout is tracked in
  [work/0022](../../work/0022-venv-per-environment/proposal.md).

## Context

Everything else in the blueprint leaves runtime specifics to per-package files. This
record makes one exception, because the problem is about the *checkout* rather than the
language: what has to stay out of a working tree that more than one environment sees.

**One working tree, two interpreters.** A sandbox container bind-mounts the host's
checkout, so a project virtualenv built on one side is visible on the other. A venv is
bound to the interpreter it was built from. `pyvenv.cfg`'s `home` names it, and every
console script's shebang carries that venv's absolute path. When uv finds a project env
whose interpreter it cannot use, it **deletes and recreates** it. With both sides
defaulting to `.venv`, each side's `uv run` destroys the other side's venv. Evidence that
this was already happening, not just possible:

- `myclickup/.venv` on a Mac checkout was built in the container (`home = /usr/bin`,
  3.12.3), so it is dead on the Mac host.
- `paperbridge/.venv` on the same checkout was built on the Mac (miniforge 3.12.12), so
  it is dead in the container.
- The 2026-08-15 "venv contest" (myclickup `work/archive/0016`) cost an hour. An earlier
  repo move broke every third-party console script, because the shebangs are absolute
  (myclickup `docs/downstream.md`).

**The name is secondary. What matters is that the two sides differ.** Naming venvs by
OS was the first proposal and fails outright, because a Linux host and a Linux container
are both "linux". The only thing that knows where a command runs is the environment
itself. uv already reads the right knob: `UV_PROJECT_ENVIRONMENT`, whose relative value
resolves against the project root, even under `uv run --project <dir>` from elsewhere.
That was verified independently on both sides, so one value serves every repo.

**Proven before anything depended on it.** On 2026-09-11, in the `nranthony` sandbox,
with the variable set per command:

- `uv sync --frozen --offline` from `myclickup/src` built `myclickup/.venv-sandbox` at the
  project root, from the uv cache alone.
- myclickup's gate passed on it (309 tests).
- The host-slot `.venv` was byte-identical afterwards.
- `git status` stayed clean, because uv writes a `*` `.gitignore` into every venv it
  builds.
- With nothing pinned, uv chose the newest interpreter in the image (3.13), where the
  deployed tool runs 3.12.

**`.local` had three names and no rule.** The template ignored `AGENTS.local.md`,
`**/AGENTS.local.md` and `.claude/settings.local.json` one by one, so every new
machine-local file needed its own line and got one only after it leaked. The suffix sits
in two places by convention (`foo.local`, `foo.local.json`).

## Decision

**1. The environment names the venv. Repos never choose it.**

- Every sandbox container exports `UV_PROJECT_ENVIRONMENT=.venv-sandbox` from its own
  configuration (compose environment). That is the sandbox tool's job, not the repo's.
- Every host leaves it unset, so uv uses `.venv`.
- There is no architecture suffix, no per-host name, and no `UV_PYTHON` in any image.
  `UV_PYTHON` acts like `--python` and would override the repo's `.python-version`.
- The one exception is recorded, not expected: two *hosts* sharing one checkout (a
  synced folder, or Windows-native Python and WSL on the same `/mnt/c` files) choose
  per-host names for that pair only. None is known today.

**2. Repos never hard-code a venv path.**

- Run everything through `uv run`.
- Where a path is unavoidable (a justfile variable, a shell script), derive it as
  `${UV_PROJECT_ENVIRONMENT:-.venv}`.
- Never select a venv by OS.

**3. `.gitignore` carries `.venv*/`.** This is hygiene, not load-bearing: uv's own
self-ignore already keeps uv-built venvs out of `git status`. A stdlib `python -m venv`
before 3.13 writes no such file.

**4. A tracked `.python-version`, pinned to a version every environment the repo runs in
actually has.** A closed-egress sandbox cannot download an interpreter, so a pin to one
it doesn't bake fails offline. Left unpinned, each environment picks its own newest.

**5. Agents touch only their own environment's venv.** They never create, sync into, or
delete another environment's; `pyvenv.cfg`'s `home` line says whose a venv is. A venv is
**rebuilt, never renamed or moved**, because the absolute shebangs don't survive a move.

**6. Permission rules: allow and ask/deny do opposite jobs, so they get opposite rules.**

Rules match literal command text and cannot read environment variables, so
`python3 x.py` does not match a `python x.py` rule.

- **Allow rules grant permission, so fewer spellings is safer.** Use the `uv run …` form
  only; one rule then covers every environment. Never put a venv path in an allow rule.
- **Ask and deny rules fence a command with side effects, so every spelling must be
  caught.** A spelling missing from the fence falls through to whatever broad allow
  exists. In a sandbox that allows `python:*`, `python3:*` and `uv run:*` and runs in
  `auto` mode, that means a classifier decides instead of a person. For each script `X`,
  the fence is:

  ```
  Bash(python*X*)
  Bash(uv run *X*)
  Bash(.venv*/bin/python*X*)
  Bash(./.venv*/bin/python*X*)
  ```

  Add `Bash(X*)` and `Bash(./X*)` if `X` is executable, and `Bash(python* -m <module>*)`
  if it can be imported as a module. Listing every spelling explicitly is also valid, but
  the list has to be complete; the common miss is `python3`.
- **The residual no rule closes is an absolute-path spelling**
  (`/workspace/<repo>/.venv-sandbox/bin/python X`). Leading wildcards are not documented
  behaviour, so don't rely on one. A command with irreversible effects should also refuse
  to act without an explicit flag (dry run by default), so the permission rules are not
  the only thing in the way.
- **Where the matching semantics come from.** These points are taken from the Claude
  Code permissions and permission-modes docs, as the sandbox tool's repo read them on the
  host on 2026-09-11:
  - a mid-rule `*` matches any text
  - deny > ask > allow, across settings scopes
  - an ask rule still prompts in `auto` mode
  - ask and deny rules match each subcommand of a `&&` compound

  They were **not** re-read from the sandbox, where the docs are unreachable. If the
  docs change any of them, this section reopens.

**7. `.local` means machine-local, never committed, for any file in any repo.**

```gitignore
*.local
*.local.*
!*.local.example*
```

- The second line covers the three names the template used to list.
- The negation re-includes a committed *example* of a local file
  (`config/hub.local.example.yaml`). An example is documentation for every clone, and
  `*.local.*` would otherwise hide every new one without a word.
- Any other legitimate collision gets a per-repo `!` exception, never a template line
  (Xcode's `*.local.entitlements` is the one found so far).
- Ignoring does not untrack. Before adopting the pair, check
  `git ls-files | grep -E '\.local($|\.)'`: a hit is a decision to make, not a change to
  let happen silently.

## Consequences

- **The sandbox half lives in the sandbox tool's repo, not here.** That is the compose
  variable, a deletion-hook carve-out for `*/.venv-sandbox/*`, and a "Python
  environments" section in its managed notice. This repo ships the rule, the template
  lines, the blueprint section, and the audit; the notice is not templated here, for the
  same reason as every other managed notice.
- **A pre-switch hazard is accepted for the rollout window.** Until a profile exports
  the variable, a bare `uv run` in a member whose `.venv` belongs to the host rebuilds
  that venv. During that window a member that can't be rebuilt offline is published from
  the host.
- **The switch rebuilds every sandbox venv from the uv cache.** A member whose wheels
  aren't cached (paperbridge on 2026-09-11) stays a host-side gate until an egress window
  warms the cache.
- **Old venvs are deleted late, by a human.** That happens only after a profile has run
  cleanly on the new name for a while, never as part of the switch.
- **The blueprint's scope line now names this exception.** Language and runtime
  specifics otherwise stay out, and the next candidate exception needs its own record.
- **`/myconv:apply-conventions` audits this in every repo, whatever its tier.** Two
  checks are mechanical rather than a matter of reading: the fence (generate each
  spelling and test it against the rules), and tracked `.local` files (list them before
  adding the pair).

## Alternatives considered

- **Name venvs by OS (`.venv-linux`, `.venv-mac`).** Rejected: a Linux host and a Linux
  container collide, which is exactly the case this record exists for.
- **Per-host names on every host (`.venv-mac`, `.venv-wsl`).** Rejected as the default:
  every host would need shell-profile setup, and forgetting it is harmless anyway. Only
  one side of a shared checkout has to differ. Kept for the two-hosts exception.
- **An architecture suffix (`.venv-sandbox-arm64`).** Rejected: no checkout is known to
  be seen by sandboxes on two architectures. Each sandbox shares a checkout only with its
  own host.
- **Pin the interpreter in the image (`UV_PYTHON`).** Rejected: it overrides the repo's
  `.python-version`, taking away the repo's one lever.
- **Put the venv outside the tree** (an absolute `UV_PROJECT_ENVIRONMENT` under a cache
  directory). This is valid for a one-off host script, and one host-side vendoring
  script does exactly that. Rejected as the rule: an absolute value needs a per-repo
  path, while a relative one is one value for every repo and stays beside the project,
  where editors look.
- **Keep naming `.local` files one by one.** Rejected: that is the rule that let each new
  machine-local file leak before it got a line.
