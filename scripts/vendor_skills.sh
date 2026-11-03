#!/usr/bin/env bash
# Vendor upstream Matt Pocock skills into this hub repo so Managed Agents sessions that mount
# the repo auto-discover them under .claude/skills/<name>/SKILL.md.
#
# Usage:
#   scripts/vendor_skills.sh                       # clone github.com/mattpocock/skills (shallow)
#   scripts/vendor_skills.sh /path/to/local/skills # copy from an existing checkout
#
# Only the exact layout .claude/skills/<name>/SKILL.md is discovered by Managed Agents,
# so each skill is flattened to that depth.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="$REPO_ROOT/.claude/skills"
SKILLS=(research grilling domain-modeling wayfinder)   # wayfinder kept for reference / interactive use
UPSTREAM="https://github.com/mattpocock/skills"

SRC="${1:-}"
CLEANUP=""
if [[ -z "$SRC" ]]; then
  SRC="$(mktemp -d)"
  CLEANUP="$SRC"
  echo "Cloning $UPSTREAM ..."
  git clone --depth 1 "$UPSTREAM" "$SRC" >/dev/null
fi
trap '[[ -n "$CLEANUP" ]] && rm -rf "$CLEANUP"' EXIT

for name in "${SKILLS[@]}"; do
  found="$(find "$SRC" -type f -path "*/$name/SKILL.md" -not -path '*/deprecated/*' | head -n1 || true)"
  if [[ -z "$found" ]]; then
    echo "WARN: skill '$name' not found under $SRC; skipping" >&2
    continue
  fi
  mkdir -p "$DEST/$name"
  cp -R "$(dirname "$found")/." "$DEST/$name/"
  echo "Vendored $name  <-  ${found#"$SRC"/}"
done

cat > "$DEST/VENDORED.md" <<EOF
Vendored from $UPSTREAM on $(date -u +%Y-%m-%d) by scripts/vendor_skills.sh.
Check the upstream LICENSE before redistributing. wayfinder-async is a local adaptation.
EOF
echo "Done. Commit .claude/skills and push."
