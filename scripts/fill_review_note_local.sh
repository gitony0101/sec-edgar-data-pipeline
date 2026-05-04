#!/usr/bin/env bash
set -euo pipefail

# scripts/fill_review_note_local.sh
# Fills specific sections of an existing FILE_NOTES note using local model (JSON-driven).

TARGET="${1:?target file path required}"
REVIEW_DIR="review"
NOTES_DIR="$REVIEW_DIR/FILE_NOTES"

# Generate safe filename for the note
SAFE_NAME=$(echo "$TARGET" | sed 's/\//__/g')
NOTE_PATH="$NOTES_DIR/${SAFE_NAME}.md"

if [ ! -f "$NOTE_PATH" ]; then
  echo "Error: Review note for $TARGET not found at $NOTE_PATH. Run ./analyze.sh review-one $TARGET first."
  exit 1
fi

# Call the JSON-driven Python helper
# It handles extraction, model call, validation, retry, and markdown update.
./scripts/fill_note_json.py "$NOTE_PATH"

echo "Review note filled: $NOTE_PATH"
