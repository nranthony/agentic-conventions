# Packaging recipes for the myconv plugin.
#
# These operate ONLY inside this repo — they never touch a consumer. Applying the
# conventions to another repo stays an agent-with-judgment job (ADR-0001); this file
# just keeps the plugin's copy of the blueprint identical to the canonical one.

PLUGIN := "plugins/myconv"
PAYLOAD := "plugins/myconv/skills/apply-conventions"

default:
    @just --list

# Copy the canonical reference/, templates/ and shared skills into the plugin tree.
sync-plugin:
    mkdir -p {{PAYLOAD}}/reference {{PAYLOAD}}/templates
    mkdir -p {{PLUGIN}}/skills/make-plan {{PLUGIN}}/skills/wrap-up
    cp -r reference/. {{PAYLOAD}}/reference/
    cp -r templates/. {{PAYLOAD}}/templates/
    cp templates/.claude/skills/make-plan/SKILL.md {{PLUGIN}}/skills/make-plan/SKILL.md
    cp templates/.claude/skills/wrap-up/SKILL.md {{PLUGIN}}/skills/wrap-up/SKILL.md
    @echo "synced → {{PLUGIN}} (review 'git diff' before committing)"

# Fail if the plugin copy has drifted from the canonical sources.
# Reports stale leftovers too: sync-plugin copies over the top and never deletes,
# so a file removed upstream shows here as "Only in ..." for you to remove by hand.
check-plugin-sync:
    #!/usr/bin/env bash
    set -euo pipefail
    status=0
    diff -r reference {{PAYLOAD}}/reference || status=1
    diff -r templates {{PAYLOAD}}/templates || status=1
    diff templates/.claude/skills/make-plan/SKILL.md {{PLUGIN}}/skills/make-plan/SKILL.md || status=1
    diff templates/.claude/skills/wrap-up/SKILL.md {{PLUGIN}}/skills/wrap-up/SKILL.md || status=1
    if [ "$status" -ne 0 ]; then
      echo "plugin payload is out of sync — run 'just sync-plugin'" >&2
      exit 1
    fi
    echo "plugin payload in sync"

# Validate the marketplace catalog and the plugin manifest.
validate:
    claude plugin validate .
    claude plugin validate ./{{PLUGIN}}

# Check that the live skills and their genericised template mirrors agree.
check-skill-mirrors:
    diff .claude/skills/make-plan/SKILL.md templates/.claude/skills/make-plan/SKILL.md
    diff .claude/skills/wrap-up/SKILL.md templates/.claude/skills/wrap-up/SKILL.md
    @echo "live skills match their template mirrors"
