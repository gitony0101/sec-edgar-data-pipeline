#!/usr/bin/env bash
set -euo pipefail

# scripts/mark_reviewed_local.sh
# Mark a file as reviewed or skipped in the queue and update reports.

TARGET="${1:?target file path required}"
STATUS="${2:-reviewed}" # Default to 'reviewed'
QUEUE_FILE="review/REVIEW_QUEUE.md"
SUMMARY_FILE="review/PROJECT_SUMMARY.md"
NEXT_STEPS_FILE="review/NEXT_STEPS.md"
FINDINGS_FILE="review/FINDINGS.md"

if [ ! -f "$QUEUE_FILE" ]; then
  echo "Error: $QUEUE_FILE not found."
  exit 1
fi

# Generate safe filename for the note validation
SAFE_NAME=$(echo "$TARGET" | sed 's/\//__/g')
NOTE_PATH="review/FILE_NOTES/${SAFE_NAME}.md"

# 1. Validate that the note exists and contains required sections
if [ ! -f "$NOTE_PATH" ]; then
  echo "Error: Review note for $TARGET not found at $NOTE_PATH. Run ./analyze.sh review-one $TARGET first."
  exit 1
fi

# Check for required headers in the note
MISSING_HEADERS=()
for header in "## REVIEW_STATUS" "## CURRENT_OBSERVATIONS" "## REVIEW_DECISION"; do
  if ! grep -q "$header" "$NOTE_PATH"; then
    MISSING_HEADERS+=("$header")
  fi
done

if [ ${#MISSING_HEADERS[@]} -ne 0 ]; then
  echo "Error: Review note is missing required headers: ${MISSING_HEADERS[*]}"
  exit 1
fi

# 2. Update the note itself (REVIEW_STATUS and REVIEW_DECISION)
sed -i.bak "/## REVIEW_STATUS/{n;s/.*/$STATUS/;}" "$NOTE_PATH"
sed -i.bak "/## REVIEW_DECISION/{n;s/.*/$STATUS/;}" "$NOTE_PATH"
rm -f "${NOTE_PATH}.bak"

# 3. Update status in REVIEW_QUEUE.md
# We replace whatever status it currently has with the new status
# sed '@' delimiter used for safety with paths
sed -i.bak "s@| .* | $TARGET |@| $STATUS | $TARGET |@" "$QUEUE_FILE"
rm -f "${QUEUE_FILE}.bak"

# 2. Append to FINDINGS.md if it's not already there
if ! grep -q "### $TARGET" "$FINDINGS_FILE"; then
  cat <<EOF >> "$FINDINGS_FILE"

### $TARGET
- **Status**: $STATUS
- **Note**: (No summary yet)
EOF
fi

# 3. Update NEXT_STEPS.md (Activity Log)
if grep -q "## Activity Log" "$NEXT_STEPS_FILE"; then
  echo "- [x] Finished review of $TARGET as $STATUS on $(date)" >> "$NEXT_STEPS_FILE"
else
  # Fallback if structure isn't normalized yet
  echo "- [x] Finished review of $TARGET as $STATUS on $(date)" >> "$NEXT_STEPS_FILE"
fi

# 4. Refresh PROJECT_SUMMARY.md
TOTAL=$(grep "| " "$QUEUE_FILE" | grep -v "Status" | grep -v "\-\-\-" | wc -l | tr -d ' ' || echo 0)
PENDING=$(grep -c "| pending |" "$QUEUE_FILE" || true)
PROGRESS=$(grep -c "| in_progress |" "$QUEUE_FILE" || true)
REVIEWED=$(grep -c "| reviewed |" "$QUEUE_FILE" || true)
SKIPPED=$(grep -c "| skipped |" "$QUEUE_FILE" || true)

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
- Marked $TARGET as $STATUS on $(date).
EOF

echo "File $TARGET marked as $STATUS. Summary updated."
