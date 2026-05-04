#!/usr/bin/env bash
set -euo pipefail

echo "# Analyze Tool Status"
echo

if [ -f "baseline_v1/README.md" ]; then
  echo "- baseline_v1: present"
else
  echo "- baseline_v1: missing"
fi

if [ -f ".brain/FILE_CATALOG.md" ]; then
  echo "- file_catalog: present"
else
  echo "- file_catalog: missing"
fi

if [ -f ".brain/reports/INDEX.md" ]; then
  echo "- report_index: present"
else
  echo "- report_index: missing"
fi

if [ -f ".brain/SUMMARY.md" ]; then
  echo "- summary: present"
else
  echo "- summary: missing"
fi

echo
echo "## Reports"
if [ -d ".brain/reports" ]; then
  find .brain/reports -maxdepth 1 -type f | sort
else
  echo "(none)"
fi
