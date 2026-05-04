#!/usr/bin/env bash
set -euo pipefail

# scripts/mark_cross_check_reviewed_local.sh
# Mark a cross-check as reviewed or skipped.

NOTE_PATH="${1:?cross check note path required}"
STATUS="${2:-reviewed}" # Default to 'reviewed'
QUEUE_FILE="review/CROSS_CHECK_QUEUE.md"
FINDINGS_FILE="review/FINDINGS.md"
NEXT_STEPS_FILE="review/NEXT_STEPS.md"

if [ ! -f "$NOTE_PATH" ]; then
  echo "Error: Cross-check note not found at $NOTE_PATH."
  exit 1
fi

# 1. Extract File A and File B from the note
# Use sed to get the line immediately following the EXACT header
FILE_A=$(sed -n '/^## FILE_A$/{n;p;}' "$NOTE_PATH" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
FILE_B=$(sed -n '/^## FILE_B$/{n;p;}' "$NOTE_PATH" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
REASON=$(sed -n '/^## SOURCE_REASON$/{n;p;}' "$NOTE_PATH" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

echo "Closing cross-check for: $FILE_A vs $FILE_B as $STATUS"

# 2. Update the note's STATUS
# Replace the line after ## STATUS
sed -i.bak "/## STATUS/{n;s/.*/$STATUS/;}" "$NOTE_PATH"
rm -f "${NOTE_PATH}.bak"

# 3. Update the CROSS_CHECK_QUEUE.md status
# We search for the row that contains both FILE_A and FILE_B
if [ -f "$QUEUE_FILE" ]; then
  python - <<EOF "$QUEUE_FILE" "$FILE_A" "$FILE_B" "$STATUS"
import sys
from pathlib import Path

queue_path = Path(sys.argv[1])
file_a = sys.argv[2]
file_b = sys.argv[3]
status = sys.argv[4]

lines = queue_path.read_text().splitlines()
updated = []
for line in lines:
    parts = [p.strip() for p in line.split("|")]
    if len(parts) >= 5 and parts[2] == file_a and parts[3] == file_b:
        updated.append(f"| {status} | {file_a} | {file_b} | {parts[4]} |")
    else:
        updated.append(line)

queue_path.write_text("\n".join(updated) + "\n")
EOF
fi

# 4. Append a stub to FINDINGS.md
cat <<EOF >> "$FINDINGS_FILE"

### Cross-Check: $FILE_A vs $FILE_B
- **Status**: $STATUS
- **Reason**: $REASON
- **Note**: (See $NOTE_PATH for details)
EOF

# 5. Append activity log to NEXT_STEPS.md
{
  echo "- [x] Finished cross-check of $FILE_A vs $FILE_B as $STATUS on $(date)"
} >> "$NEXT_STEPS_FILE"

echo "Cross-check closure complete. Queue, note, and findings updated."
