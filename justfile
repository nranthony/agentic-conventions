# Packaging recipes for the myconv plugin.
#
# These operate ONLY inside this repo — they never touch a consumer. Applying the
# conventions to another repo stays an agent-with-judgment job (ADR-0001); this file
# just keeps the plugin's copy of the blueprint identical to the canonical one.
#
# One home per role (work/0011, WP7): the four shared skills are canonical at
# .claude/skills/<name>/, the plugin payload under plugins/myconv/ is generated from
# them, and the deployment copy in a container's ~/.claude/skills/myconv/ is owned by
# the sandbox repo — never edited from here.

PLUGIN := "plugins/myconv"
PAYLOAD := "plugins/myconv/skills/apply-conventions"

default:
    @just --list

# Copy the canonical reference/, templates/ and shared skills into the plugin tree.
# The shared-skill list is derived from .claude/skills/*/ — adding a fifth skill needs
# no edit here, and cannot be silently under-synced.
sync-plugin:
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p {{PAYLOAD}}/reference {{PAYLOAD}}/templates
    cp -r reference/. {{PAYLOAD}}/reference/
    cp -r templates/. {{PAYLOAD}}/templates/
    for dir in .claude/skills/*/; do
      name=$(basename "${dir}")
      mkdir -p "{{PLUGIN}}/skills/${name}"
      cp -r "${dir}." "{{PLUGIN}}/skills/${name}/"
      echo "  skill: ${name}"
    done
    echo "synced → {{PLUGIN}} (review 'git diff' before committing)"

# Fail if the plugin copy has drifted from the canonical sources.
# Reports stale leftovers too: sync-plugin copies over the top and never deletes,
# so a file removed upstream shows here as "Only in ..." for you to remove by hand.
check-plugin-sync:
    #!/usr/bin/env bash
    set -euo pipefail
    status=0
    diff -r reference {{PAYLOAD}}/reference || status=1
    diff -r templates {{PAYLOAD}}/templates || status=1
    for dir in .claude/skills/*/; do
      name=$(basename "${dir}")
      if [ ! -d "{{PLUGIN}}/skills/${name}" ]; then
        echo "missing from payload: {{PLUGIN}}/skills/${name}" >&2
        status=1
        continue
      fi
      diff -r "${dir}" "{{PLUGIN}}/skills/${name}" || status=1
    done
    # A payload skill with no canonical source is stale — except apply-conventions,
    # which is authored in place inside the plugin and has no copy under .claude/skills/.
    for dir in {{PLUGIN}}/skills/*/; do
      name=$(basename "${dir}")
      if [ "${name}" = "apply-conventions" ]; then continue; fi
      if [ ! -d ".claude/skills/${name}" ]; then
        echo "stale payload skill with no canonical source: ${dir}" >&2
        status=1
      fi
    done
    if [ "${status}" -ne 0 ]; then
      echo "plugin payload is out of sync — run 'just sync-plugin'" >&2
      exit 1
    fi
    echo "plugin payload in sync"

# No relative link may escape the plugin payload: an installed plugin cannot read the
# rest of this repo, so '](../' resolves nowhere for every consumer.
check-plugin-links:
    #!/usr/bin/env bash
    set -euo pipefail
    if rg -n '\]\(\.\./' {{PLUGIN}}; then
      echo "payload links escape the plugin — cite ADRs by number and bare path instead" >&2
      exit 1
    fi
    echo "no escaping links in the plugin payload"

# The two manifests must agree on the version; nothing else enforces it.
check-versions:
    #!/usr/bin/env bash
    set -euo pipefail
    plugin_v=$(jq -r '.version' {{PLUGIN}}/.claude-plugin/plugin.json)
    market_v=$(jq -r '.plugins[] | select(.name == "myconv") | .version' .claude-plugin/marketplace.json)
    if [ "${plugin_v}" != "${market_v}" ]; then
      echo "version mismatch: plugin.json ${plugin_v} != marketplace.json ${market_v}" >&2
      exit 1
    fi
    echo "versions agree: ${plugin_v}"

# Compare the product tier against the sandbox repo's vendored copy, so a stale vendor
# is visible from here. Point at the sandbox checkout with the SANDBOX_REPO env var or
# a gitignored .sandbox-repo.local holding the path; unconfigured, this skips.
# Never diff against ~/.claude/skills/myconv/ — that is a derived cache two steps
# further down the chain and may legitimately be mid-convergence.
check-vendored:
    #!/usr/bin/env bash
    set -euo pipefail
    repo="${SANDBOX_REPO:-}"
    if [ -z "${repo}" ] && [ -f .sandbox-repo.local ]; then
      repo=$(tr -d '[:space:]' < .sandbox-repo.local)
    fi
    if [ -z "${repo}" ]; then
      echo "check-vendored: SKIPPED — set SANDBOX_REPO or write the sandbox checkout path into .sandbox-repo.local"
      exit 0
    fi
    vendored="${repo}/sandbox_templates/skills/myconv"
    if [ ! -d "${vendored}" ]; then
      echo "check-vendored: SKIPPED — no vendored copy at ${vendored}"
      exit 0
    fi
    if ! diff -r {{PLUGIN}} "${vendored}"; then
      echo "vendored copy differs — the human re-vendors from the sandbox repo ('just sync-skills' there)" >&2
      exit 1
    fi
    echo "vendored copy matches {{PLUGIN}}"

# Validate the marketplace catalog and the plugin manifest.
validate:
    claude plugin validate .
    claude plugin validate ./{{PLUGIN}}

# Everything that must hold before a commit.
check: check-plugin-sync check-plugin-links check-versions check-vendored validate
    @echo "all checks passed"
