#!/usr/bin/env bash
set -euo pipefail

# scripts/prepare_cross_check_note_local.sh
# Prepare a cross-check note for a pair of files.

QUEUE_FILE="review/CROSS_CHECK_QUEUE.md"
NOTES_DIR="review/FILE_NOTES"
X_NOTES_DIR="review/CROSS_CHECK_NOTES"
mkdir -p "$X_NOTES_DIR"

# 1. Determine the pair
if [ $# -eq 2 ]; then
  FILE_A="$1"
  FILE_B="$2"
  REASON="Explicitly requested"
  MODE="manual"
else
  # Pull the first pending pair from the queue
  if [ ! -f "$QUEUE_FILE" ]; then
    echo "Error: $QUEUE_FILE not found."
    exit 1
  fi
  
  PENDING_LINE=$(grep "| pending |" "$QUEUE_FILE" | head -n 1)
  if [ -z "$PENDING_LINE" ]; then
    echo "No pending cross-check pairs found."
    exit 0
  fi
  
  FILE_A=$(echo "$PENDING_LINE" | awk -F'|' '{print $3}' | tr -d ' ')
  FILE_B=$(echo "$PENDING_LINE" | awk -F'|' '{print $4}' | tr -d ' ')
  REASON=$(echo "$PENDING_LINE" | awk -F'|' '{print $5}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
  MODE="queue"
fi

echo "Preparing cross-check for: $FILE_A vs $FILE_B"

# 2. Extract context from FILE_NOTES
get_context() {
  local target="$1"
  local safe_name=$(echo "$target" | sed 's/\//__/g')
  local note_path="$NOTES_DIR/${safe_name}.md"
  
  if [ ! -f "$note_path" ]; then
    echo "ROLE: unknown (note missing)"
    echo "OBS: none"
    return
  fi
  
  local role=$(grep "## ROLE" -A 2 "$note_path" | tail -n 1 | tr -d ' ')
  local obs=$(sed -n '/## CURRENT_OBSERVATIONS/,/## POSSIBLE_OVERLAP/{/## CURRENT_OBSERVATIONS/d;/## POSSIBLE_OVERLAP/d;p;}' "$note_path" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
  
  echo "ROLE: $role"
  echo "OBS: ${obs:-None}"
}

CONTEXT_A=$(get_context "$FILE_A")
CONTEXT_B=$(get_context "$FILE_B")

ROLE_A=$(echo "$CONTEXT_A" | grep "ROLE:" | cut -d' ' -f2-)
OBS_A=$(echo "$CONTEXT_A" | grep "OBS:" | cut -d' ' -f2-)

ROLE_B=$(echo "$CONTEXT_B" | grep "ROLE:" | cut -d' ' -f2-)
OBS_B=$(echo "$CONTEXT_B" | grep "OBS:" | cut -d' ' -f2-)

# 3. Create the cross-check note
SAFE_A=$(echo "$FILE_A" | sed 's/\//__/g')
SAFE_B=$(echo "$FILE_B" | sed 's/\//__/g')
X_NOTE_PATH="$X_NOTES_DIR/${SAFE_A}_vs_${SAFE_B}.md"

cat <<EOF > "$X_NOTE_PATH"
# CROSS CHECK NOTE

## STATUS
pending

## FILE_A
$FILE_A

## FILE_B
$FILE_B

## FILE_A_ROLE
$ROLE_A

## FILE_B_ROLE
$ROLE_B

## FILE_A_OBSERVATIONS
$OBS_A

## FILE_B_OBSERVATIONS
$OBS_B

## POSSIBLE_SHARED_CONCERNS
- [ ] TODO: Compare logic and state sharing.

## DIFFERENCE_CHECKPOINTS
- [ ] TODO: Identify clear divisions of responsibility.

## NEXT_ACTION
- [ ] Perform manual or model-assisted joint analysis of the two files.

## SOURCE_REASON
$REASON
EOF

# 4. Update the queue status
if [ "$MODE" == "queue" ]; then
  # Use @ as delimiter because of paths
  sed -i.bak "s@| pending | $FILE_A | $FILE_B |@| in_progress | $FILE_A | $FILE_B |@" "$QUEUE_FILE"
  rm -f "${QUEUE_FILE}.bak"
fi

echo "Cross-check note prepared: $X_NOTE_PATH"
