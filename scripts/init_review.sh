#!/usr/bin/env bash
set -euo pipefail

# scripts/init_review.sh
# Initialize the review workspace from the current .brain artifacts.

REVIEW_DIR="review"
NOTES_DIR="$REVIEW_DIR/FILE_NOTES"
QUEUE_FILE="$REVIEW_DIR/REVIEW_QUEUE.md"
FINDINGS_FILE="$REVIEW_DIR/FINDINGS.md"
SUMMARY_FILE="$REVIEW_DIR/PROJECT_SUMMARY.md"
NEXT_STEPS_FILE="$REVIEW_DIR/NEXT_STEPS.md"
CATALOG=".brain/FILE_CATALOG.md"

echo "Initializing review workspace in $REVIEW_DIR/..."

mkdir -p "$NOTES_DIR"

# 1. Initialize REVIEW_QUEUE.md
if [ ! -f "$CATALOG" ]; then
  echo "Error: $CATALOG not found. Run ./analyze.sh core first."
  exit 1
fi

cat <<EOF > "$QUEUE_FILE"
# Review Queue

| Status | File Path | Role |
| :--- | :--- | :--- |
EOF

# Parse CATALOG for entries
current_file=""
while IFS= read -r line; do
  if [[ "$line" =~ ^###\ (.*) ]]; then
    current_file="${BASH_REMATCH[1]}"
  elif [[ "$line" =~ ^-\ role_label:\ (.*) ]]; then
    role_label="${BASH_REMATCH[1]}"
    echo "| pending | $current_file | $role_label |" >> "$QUEUE_FILE"
  fi
done < "$CATALOG"

# 2. Initialize FINDINGS.md
cat <<EOF > "$FINDINGS_FILE"
# Review Findings

## Redundancy & Merges
(No findings yet)

## Dead Code
(No findings yet)

## Architectural Issues
(No findings yet)
EOF

# 3. Initialize PROJECT_SUMMARY.md
cat <<EOF > "$SUMMARY_FILE"
# Project Review Summary

- Total Files: $(grep -c "| pending |" "$QUEUE_FILE" || echo 0)
- Reviewed: 0
- Progress: 0%

## Recent Activity
- Workspace initialized on $(date).
EOF

# 4. Initialize NEXT_STEPS.md
cat <<EOF > "$NEXT_STEPS_FILE"
# Next Steps

## Current Todo
- [ ] Run \`./analyze.sh review-next\` to prepare the next pending file for review.
- [ ] Run \`./analyze.sh review-one <path>\` to prepare a specific file.
- [ ] Record findings in \`review/FILE_NOTES/\`.
- [ ] Run \`./analyze.sh mark-reviewed <path>\` when finished.
- [ ] Update \`review/FINDINGS.md\` with cross-file observations.

## Activity Log
- Workspace initialized on $(date).
EOF

echo "Done. Review workspace ready at $REVIEW_DIR/"
