#!/usr/bin/env bash
set -euo pipefail

TARGET="${1:?target required}"

SAFE_NAME="$(python - <<'PY' "$TARGET"
import sys
print(sys.argv[1].replace("/", "__"))
PY
)"

REPORT=".brain/reports/${SAFE_NAME}.md"

if [ ! -f "$REPORT" ]; then
  echo "Report not found: $REPORT" >&2
  echo "Run: ./analyze.sh file $TARGET" >&2
  exit 1
fi

echo "REPORT=$REPORT"
echo
sed -n '1,260p' "$REPORT"
