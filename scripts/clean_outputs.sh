#!/usr/bin/env bash
set -euo pipefail

echo "Cleaning generated analysis outputs..."

rm -f .brain/FILE_CATALOG.md
rm -f .brain/SUMMARY.md
rm -f .brain/reports/*.md 2>/dev/null || true

mkdir -p .brain/reports

echo "Reinitializing minimal placeholders..."

cat > .brain/FILE_CATALOG.md <<'EOT'
# File Catalog

## Rules
- This file is generated from controller outputs.
- Role codes and action codes come from deterministic scripts.
- Short descriptions are draft-only unless otherwise marked.

## Entries
EOT

cat > .brain/reports/INDEX.md <<'EOT'
# Report Index

## Generated Reports
EOT

echo "Done."
