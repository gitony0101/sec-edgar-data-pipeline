#!/usr/bin/env bash
set -euo pipefail

mkdir -p .brain
mkdir -p .brain/reports

CORE_FILES=(
  "sec_edgar_pipeline/__main__.py"
  "sec_edgar_pipeline/pipeline.py"
  "sec_edgar_pipeline/sec_client.py"
  "sec_edgar_pipeline/converters.py"
  "sec_edgar_pipeline/form_map.py"
  "sec_edgar_pipeline/config.py"
)

# Rebuild catalog from scratch for the current batch
cat > .brain/FILE_CATALOG.md <<'EOT'
# File Catalog

## Rules
- This file is generated from controller outputs.
- Role codes and action codes come from deterministic scripts.
- Short descriptions are draft-only unless otherwise marked.

## Entries
EOT

# Add a batch marker to the run log
{
  echo "## Batch Run"
  echo "- timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
  echo
} >> .brain/RUN_LOG.md

# Rebuild report index
cat > .brain/reports/INDEX.md <<'EOT'
# Report Index

## Generated Reports
EOT

for target in "${CORE_FILES[@]}"; do
  echo "=== ANALYZING: $target ==="

  scripts/catalog_append.sh "$target" >/dev/null

  OUT="$(scripts/analyze_one.sh "$target")"
  REPORT="$(printf '%s\n' "$OUT" | awk -F= '/^REPORT=/{print $2}' | tail -n 1)"

  {
    echo "- $target"
    echo "  - report: $REPORT"
  } >> .brain/reports/INDEX.md
done

echo
echo "===== FILE CATALOG ====="
sed -n '1,300p' .brain/FILE_CATALOG.md

echo
echo "===== REPORT INDEX ====="
sed -n '1,300p' .brain/reports/INDEX.md
