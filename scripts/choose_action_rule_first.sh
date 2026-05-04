#!/usr/bin/env bash
set -euo pipefail

TARGET="${1:?target required}"
CARD_FILE=".brain/ACTION_RULE_CARD.md"

python scripts/extract_python_card.py "$TARGET" > "$CARD_FILE"

LINE_COUNT="$(grep '^- line_count:' "$CARD_FILE" | awk '{print $3}')"

if [ "${LINE_COUNT:-0}" -le 80 ]; then
  echo "1"
else
  echo "2"
fi
