#!/usr/bin/env bash
# apply.sh — scaffold the agentic-conventions templates into a target repo.
#
#   scripts/apply.sh [TARGET_DIR] [--force]
#
# TARGET_DIR defaults to the current directory. Existing files are left
# untouched unless --force is given. {{PROJECT_NAME}} is replaced with the
# target repo's directory name. After copying, thin CLAUDE.md entrypoints are
# regenerated next to every AGENTS.md.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATES="$HERE/templates"

TARGET="."
FORCE=0
for arg in "$@"; do
  case "$arg" in
    --force) FORCE=1 ;;
    *) TARGET="$arg" ;;
  esac
done

TARGET="$(cd "$TARGET" && pwd)"
PROJECT_NAME="$(basename "$TARGET")"

[ -d "$TEMPLATES" ] || { echo "error: templates/ not found at $TEMPLATES" >&2; exit 1; }

copied=0 skipped=0
while IFS= read -r -d '' src; do
  rel="${src#"$TEMPLATES"/}"
  dst="$TARGET/$rel"
  if [ -e "$dst" ] && [ "$FORCE" -eq 0 ]; then
    echo "skip (exists): $rel"; skipped=$((skipped+1)); continue
  fi
  mkdir -p "$(dirname "$dst")"
  # substitute placeholders on the way in
  sed "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$src" > "$dst"
  case "$rel" in *.sh) chmod +x "$dst" ;; esac
  echo "wrote: $rel"; copied=$((copied+1))
done < <(find "$TEMPLATES" -type f -print0)

# Regenerate thin CLAUDE.md entrypoints if the target is a git repo.
if git -C "$TARGET" rev-parse --show-toplevel >/dev/null 2>&1; then
  ( cd "$TARGET"
    while IFS= read -r -d '' f; do
      printf '# CLAUDE.md\n@AGENTS.md\n' > "$(dirname "$f")/CLAUDE.md"
    done < <(find . -name AGENTS.md -not -path './.git/*' -print0) )
  echo "synced CLAUDE.md entrypoints"
fi

echo "done: $copied written, $skipped skipped → $TARGET"
