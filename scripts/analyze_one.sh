#!/usr/bin/env bash
set -euo pipefail

TARGET="${1:?target required}"
mkdir -p .brain/reports

OUT="$(scripts/controller_rule_first_v2.sh "$TARGET")"

ACTION="$(printf '%s\n' "$OUT" | awk -F= '/^ACTION=/{print $2}' | tail -n 1)"
ROLE="$(printf '%s\n' "$OUT" | awk -F= '/^ROLE=/{print $2}' | tail -n 1)"
ROLE_LABEL="$(printf '%s\n' "$OUT" | awk -F= '/^ROLE_LABEL=/{print $2}' | tail -n 1)"

SAFE_NAME="$(python - <<'PY' "$TARGET"
import sys
print(sys.argv[1].replace("/", "__"))
PY
)"

REPORT=".brain/reports/${SAFE_NAME}.md"

{
  echo "# Analysis Report"
  echo
  echo "- target: $TARGET"
  echo "- action: $ACTION"
  echo "- role: $ROLE"
  echo "- role_label: $ROLE_LABEL"
  echo
  echo "## Deterministic Draft"
  echo
  scripts/render_draft_from_role.sh "$TARGET"
  echo
  if [ "$ACTION" = "2" ]; then
    echo "## First 80 Lines"
    echo
    echo '```python'
    sed -n '1,80p' "$TARGET"
    echo '```'
    echo
  fi
} > "$REPORT"

echo "REPORT=$REPORT"
sed -n '1,220p' "$REPORT"
