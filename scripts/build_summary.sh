#!/usr/bin/env bash
set -euo pipefail

TMP_STATS="$(mktemp)"

awk '
/^- role_label: / {
  label=$0
  sub(/^- role_label: /, "", label)
  count[label]++
}
END {
  for (k in count) {
    print "- " k ": " count[k]
  }
}
' .brain/FILE_CATALOG.md | sort > "$TMP_STATS"

cat > .brain/SUMMARY.md <<'EOT'
# Local Analysis Summary

## Overview
This summary is generated from deterministic outputs.

## Role Statistics
EOT

if [ -s "$TMP_STATS" ]; then
  cat "$TMP_STATS" >> .brain/SUMMARY.md
else
  echo "- none" >> .brain/SUMMARY.md
fi

cat >> .brain/SUMMARY.md <<'EOT'

## File Catalog
EOT

echo >> .brain/SUMMARY.md
tail -n +2 .brain/FILE_CATALOG.md >> .brain/SUMMARY.md

cat >> .brain/SUMMARY.md <<'EOT'

## Report Index
EOT

echo >> .brain/SUMMARY.md
tail -n +2 .brain/reports/INDEX.md >> .brain/SUMMARY.md

cat >> .brain/SUMMARY.md <<'EOT'

## Current Status
- baseline_v1 is operational
- rule-first classification is active
- deterministic draft rendering is active
- reports are generated under .brain/reports
EOT

rm -f "$TMP_STATS"

echo "Updated .brain/SUMMARY.md"
sed -n '1,260p' .brain/SUMMARY.md
