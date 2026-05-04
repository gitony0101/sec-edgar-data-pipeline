#!/usr/bin/env bash
set -euo pipefail

# scripts/review_next_file_local.sh
# Find the next pending file in the queue, mark as in_progress, and prepare notes.

QUEUE_FILE="review/REVIEW_QUEUE.md"
SUMMARY_FILE="review/PROJECT_SUMMARY.md"
NEXT_STEPS_FILE="review/NEXT_STEPS.md"

if [ ! -f "$QUEUE_FILE" ]; then
  echo "Error: $QUEUE_FILE not found. Run ./analyze.sh init-review first."
  exit 1
fi

# 1. Find the first pending file
# Format: | pending | path | role |
NEXT_FILE=$(grep "| pending |" "$QUEUE_FILE" | head -n 1 | awk -F'|' '{print $3}' | tr -d ' ')

if [ -z "$NEXT_FILE" ]; then
  echo "No more pending files in the review queue."
  exit 0
fi

echo "Next file for review: $NEXT_FILE"

# 2. Mark as in_progress in the queue
# We use sed to replace the first occurrence of pending for this specific file
# Use @ as delimiter because | is used in the pattern
sed -i.bak "s@| pending | $NEXT_FILE @| in_progress | $NEXT_FILE @" "$QUEUE_FILE"
rm -f "${QUEUE_FILE}.bak"

# 3. Call review_one_file_local.sh
scripts/review_one_file_local.sh "$NEXT_FILE"

# 4. Update NEXT_STEPS.md (append log)
{
  echo "- [x] Started review of $NEXT_FILE on $(date)"
} >> "$NEXT_STEPS_FILE"

# 5. Refresh PROJECT_SUMMARY.md
# Count total data rows by excluding header and separator
TOTAL=$(grep "| " "$QUEUE_FILE" | grep -v "Status" | grep -v "\-\-\-" | wc -l | tr -d ' ' || echo 0)
PENDING=$(grep -c "| pending |" "$QUEUE_FILE" || true)
PROGRESS=$(grep -c "| in_progress |" "$QUEUE_FILE" || true)
REVIEWED=$(grep -c "| reviewed |" "$QUEUE_FILE" || true)
SKIPPED=$(grep -c "| skipped |" "$QUEUE_FILE" || true)

# Calculate percentage (simple integer math)
if [ "$TOTAL" -gt 0 ]; then
  PERCENT=$(( (REVIEWED + SKIPPED) * 100 / TOTAL ))
else
  PERCENT=0
fi

cat <<EOF > "$SUMMARY_FILE"
# Project Review Summary

- Total Files: $TOTAL
- Pending: $PENDING
- In Progress: $PROGRESS
- Reviewed: $REVIEWED
- Skipped: $SKIPPED
- Overall Progress: $PERCENT%

## Recent Activity
- Prepared $NEXT_FILE for review on $(date).
EOF

echo "Status updated for $NEXT_FILE. Workspace is ready for manual review."
