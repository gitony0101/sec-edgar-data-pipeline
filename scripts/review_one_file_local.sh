#!/usr/bin/env bash
set -euo pipefail

# scripts/review_one_file_local.sh
# Prepare a single-file review note from existing deterministic artifacts.

TARGET="${1:?target file path required}"
REVIEW_DIR="review"
NOTES_DIR="$REVIEW_DIR/FILE_NOTES"
mkdir -p "$NOTES_DIR"

# Generate safe filename for the note
SAFE_NAME=$(echo "$TARGET" | sed 's/\//__/g')
NOTE_PATH="$NOTES_DIR/${SAFE_NAME}.md"

# 1. Identify existing report in .brain/reports/
REPORT=".brain/reports/${SAFE_NAME}.md"

if [ ! -f "$REPORT" ]; then
  echo "Warning: No deterministic report found at $REPORT. Run ./analyze.sh file $TARGET first."
  # We still proceed but facts will be limited to what we can extract now
fi

# 2. Gather ROLE and basic metadata from REPORT if available
ROLE="unknown"
if [ -f "$REPORT" ]; then
  ROLE=$(grep "role_label:" "$REPORT" | head -n 1 | awk -F': ' '{print $2}')
fi

# 3. Extract fresh AST facts using extract_python_card.py if it's a python file
FACTS_OUTPUT=""
if [[ "$TARGET" == *.py ]]; then
  FACTS_OUTPUT=$(python scripts/extract_python_card.py "$TARGET")
else
  FACTS_OUTPUT="No AST facts available (not a Python file)."
fi

# 4. Write the review note
cat <<EOF > "$NOTE_PATH"
# FILE REVIEW NOTE

## FILE_PATH
$TARGET

## ROLE
$ROLE

## REVIEW_STATUS
pending

## FACTS
$FACTS_OUTPUT

## CURRENT_OBSERVATIONS
- [ ] TODO: Add observations.

## POSSIBLE_OVERLAP
- (No overlap identified yet)

## POSSIBLE_CLEANUP
- (No cleanup suggestions yet)

## NEEDS_CROSS_CHECK_WITH
- (No cross-check targets identified yet)

## NEXT_ACTION
- [ ] Perform analysis.

## REVIEW_DECISION
pending
EOF

echo "Review note prepared: $NOTE_PATH"
