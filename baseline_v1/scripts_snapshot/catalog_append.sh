#!/usr/bin/env bash
set -euo pipefail

TARGET="${1:?target required}"

OUT="$(scripts/controller_rule_first_v2.sh "$TARGET")"

ACTION="$(printf '%s\n' "$OUT" | awk -F= '/^ACTION=/{print $2}' | tail -n 1)"
ROLE="$(printf '%s\n' "$OUT" | awk -F= '/^ROLE=/{print $2}' | tail -n 1)"
ROLE_LABEL="$(printf '%s\n' "$OUT" | awk -F= '/^ROLE_LABEL=/{print $2}' | tail -n 1)"

{
  echo "### $TARGET"
  echo
  echo "- action: $ACTION"
  echo "- role: $ROLE"
  echo "- role_label: $ROLE_LABEL"
  echo
} >> .brain/FILE_CATALOG.md
