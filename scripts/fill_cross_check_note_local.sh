#!/usr/bin/env bash
set -euo pipefail

# scripts/fill_cross_check_note_local.sh
# Fills specific sections of an existing CROSS_CHECK_NOTE using local model.

NOTE_PATH="${1:?cross check note path required}"

if [ ! -f "$NOTE_PATH" ]; then
  echo "Error: Cross-check note not found at $NOTE_PATH."
  exit 1
fi

# 1. Gather context from the existing note
# We pull FILE_A_OBSERVATIONS and FILE_B_OBSERVATIONS as context
CONTEXT_A=$(sed -n '/## FILE_A_OBSERVATIONS/,/## POSSIBLE_SHARED_CONCERNS/{/## FILE_A_OBSERVATIONS/d;/## POSSIBLE_SHARED_CONCERNS/d;p;}' "$NOTE_PATH")
CONTEXT_B=$(sed -n '/## FILE_B_OBSERVATIONS/,/## POSSIBLE_SHARED_CONCERNS/{/## FILE_B_OBSERVATIONS/d;/## POSSIBLE_SHARED_CONCERNS/d;p;}' "$NOTE_PATH")
REASON=$(grep "## SOURCE_REASON" -A 2 "$NOTE_PATH" | tail -n 1)

# 2. Model invocation or fallback
MODEL_OUTPUT=""
FALLBACK_CONTENT="## POSSIBLE_SHARED_CONCERNS
- Uncertain: Possible shared state or logic (model failed).

## DIFFERENCE_CHECKPOINTS
- Uncertain: Differences in responsibility not analyzed (model failed).

## NEXT_ACTION
- Possible: Perform manual joint analysis of File A and File B."

if ! command -v codex &> /dev/null; then
  echo "Warning: 'codex' command not found. Using conservative placeholders."
  MODEL_OUTPUT="$FALLBACK_CONTENT"
else
  echo "Invoking local model for cross-check analysis..."
  if ! MODEL_OUTPUT=$(codex exec \
    --oss \
    -c oss_provider=ollama \
    -m gemma4:e2b \
    --full-auto \
"STRICT TASK: You are a senior architect.
Compare two files based on these observations and reason for cross-check.
Produce three short sections using the exact headings below.
Use concise bullet points. Be conservative.
Prefixes to use:
- Observed: (from facts)
- Possible: (reasonable inference)
- Uncertain: (if data is missing)

Reason for cross-check:
$REASON

Observations for File A:
$CONTEXT_A

Observations for File B:
$CONTEXT_B

Headers to use:
## POSSIBLE_SHARED_CONCERNS
## DIFFERENCE_CHECKPOINTS
## NEXT_ACTION" 2>/dev/null); then
    echo "Warning: Local model (codex) execution failed. Using conservative placeholders."
    MODEL_OUTPUT="$FALLBACK_CONTENT"
  fi
fi

# 3. Update the note using Python for robust section replacement
python - <<EOF "$NOTE_PATH" "$MODEL_OUTPUT"
import sys
import re

note_path = sys.argv[1]
model_output = sys.argv[2]

with open(note_path, 'r') as f:
    lines = f.readlines()

headers_to_fill = [
    "POSSIBLE_SHARED_CONCERNS",
    "DIFFERENCE_CHECKPOINTS",
    "NEXT_ACTION"
]

# Extract sections from model_output
sections_data = {}
for header in headers_to_fill:
    pattern = rf"## {header}\s*\n(.*?)(?=## |\Z)"
    match = re.search(pattern, model_output, re.DOTALL | re.IGNORECASE)
    if match and match.group(1).strip():
        sections_data[header] = match.group(1).strip()
    else:
        sections_data[header] = "- Uncertain: Not provided by model in expected format."

# Reconstruct the file line by line
new_lines = []
skip_mode = False
for line in lines:
    matched_header = None
    for h in headers_to_fill:
        if line.startswith(f"## {h}"):
            matched_header = h
            break
    
    if matched_header:
        new_lines.append(line)
        new_lines.append(sections_data[matched_header] + "\n")
        new_lines.append("\n")
        skip_mode = True
        continue
    
    if skip_mode:
        if line.startswith("## "):
            skip_mode = False
        else:
            continue
            
    if not skip_mode:
        new_lines.append(line)

with open(note_path, 'w') as f:
    f.writelines(new_lines)
EOF

echo "Cross-check note filled: $NOTE_PATH"
