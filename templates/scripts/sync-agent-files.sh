#!/usr/bin/env bash
# scripts/sync-agent-files.sh — regenerate a thin CLAUDE.md next to every AGENTS.md.
# Self-contained (no dependency on agentic-conventions); safe to run repeatedly.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
while IFS= read -r -d '' f; do
  printf '# CLAUDE.md\n@AGENTS.md\n' > "$(dirname "$f")/CLAUDE.md"
done < <(find . -name AGENTS.md -not -path './.git/*' -print0)
echo "Synced CLAUDE.md entrypoints."
