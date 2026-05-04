#!/usr/bin/env bash
set -euo pipefail

# scripts/refresh_review_workspace_local.sh
# Orchestrates the refresh of all top-level review artifacts.

echo "Starting review workspace refresh..."

# 1. Build cross-check queue
echo "[1/3] Building cross-check queue..."
if ! scripts/build_cross_check_queue_local.sh; then
  echo "Error: Failed to build cross-check queue."
  exit 1
fi

# 2. Refresh findings summary
echo "[2/3] Refreshing findings summary..."
if ! scripts/refresh_findings_summary_local.sh; then
  echo "Error: Failed to refresh findings summary."
  exit 1
fi

# 3. Refresh project dashboard
echo "[3/3] Refreshing project dashboard..."
if ! scripts/refresh_project_dashboard_local.sh; then
  echo "Error: Failed to refresh project dashboard."
  exit 1
fi

echo "Workspace refresh complete. See review/PROJECT_DASHBOARD.md for status."
