#!/usr/bin/env bash
set -euo pipefail

CATALOG=".brain/FILE_CATALOG.md"

if [ ! -f "$CATALOG" ]; then
  echo "Catalog not found: $CATALOG" >&2
  echo "Run: ./analyze.sh core" >&2
  exit 1
fi

echo "# Catalog List"
echo

awk '
BEGIN {
  target=""; action=""; role=""; role_label="";
}
/^### / {
  if (target != "") {
    printf "- %s | action=%s | role=%s | role_label=%s\n", target, action, role, role_label;
  }
  target=$0;
  sub(/^### /, "", target);
  action=""; role=""; role_label="";
}
/^- action: / {
  action=$0;
  sub(/^- action: /, "", action);
}
/^- role: / {
  role=$0;
  sub(/^- role: /, "", role);
}
/^- role_label: / {
  role_label=$0;
  sub(/^- role_label: /, "", role_label);
}
END {
  if (target != "") {
    printf "- %s | action=%s | role=%s | role_label=%s\n", target, action, role, role_label;
  }
}
' "$CATALOG"
