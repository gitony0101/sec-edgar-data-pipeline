#!/usr/bin/env bash
set -euo pipefail

# scripts/run_gemini_task.sh
# Entrypoint for Gemini to perform INFRASTRUCTURE, DEBUGGING, and WORKFLOW tasks.
# Note: Repository review, memory, and patch tasks belong to the local gemma4:e2b path.

# Robustly resolve repository root relative to the script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
AGENTS_FILE="$ROOT_DIR/AGENTS.md"
TMP_DIR="$ROOT_DIR/.brain/gemini_runner"
PROMPT_FILE="$TMP_DIR/last_prompt.txt"

mkdir -p "$TMP_DIR"

if [[ ! -f "$AGENTS_FILE" ]]; then
  echo "Error: AGENTS.md not found in repository root: $ROOT_DIR"
  exit 1
fi

if [[ $# -gt 0 ]]; then
  TASK_TEXT="$*"
else
  TASK_TEXT="$(cat)"
fi

# Determine Task Mode using heuristic (for infrastructure/workflow tasks)
TASK_TEXT_LOWER=$(echo "$TASK_TEXT" | tr '[:upper:]' '[:lower:]')
if echo "$TASK_TEXT_LOWER" | grep -qE "append|update|write|apply|modify|patch"; then
  TASK_MODE_HEADER="TASK MODE
- mode: infrastructure_write_allowed
- read_file: available
- shell: available
- write_file: available
- subagents: unavailable

EXECUTION RULES
- Use only explicitly available capabilities.
- Gemini role: build infrastructure, modify scripts, debug workflow.
- Do not perform repository review/memory/patch tasks (those belong to gemma4:e2b).
- Do not claim completion unless the target infrastructure has actually changed."
else
  TASK_MODE_HEADER="TASK MODE
- mode: infrastructure_read_only
- read_file: available
- shell: available
- write_file: unavailable
- subagents: unavailable

EXECUTION RULES
- Use only explicitly available capabilities.
- Gemini role: inspect repository, plan workflow improvements.
- Do not perform repository review/memory/patch tasks (those belong to gemma4:e2b).
- Do not claim completion for file updates."
fi

cat > "$PROMPT_FILE" <<EOF
You are a development agent operating inside this repository to improve its workflow and infrastructure.

$TASK_MODE_HEADER

IMPORTANT: All repository review, memory updates, and code improvement tasks belong to the local model (gemma4:e2b). Your role is only to BUILD and DEBUG the system.

Before doing anything else, you must read and follow the repository operating contract below.

===== BEGIN AGENTS.md =====
$(cat "$AGENTS_FILE")
===== END AGENTS.md =====

You must obey these rules for this round.

Before executing the task, first output exactly these 4 items:
1. AGENTS.md acknowledged
2. Task type (Infrastructure/Debug/Workflow)
3. Round objective
4. Rules from AGENTS.md that constrain this task

Then execute the task.

Important:
- Do not skip the AGENTS.md acknowledgment step.
- Stop immediately after completing the requested task.
- Do not append extra repository impressions, future role assumptions, or next-step suggestions unless explicitly asked.

===== TASK =====
$TASK_TEXT
EOF

echo "Prompt written to: $PROMPT_FILE"
echo "Running Gemini for Infrastructure/Workflow task..."

# Invoke the Gemini CLI with the generated prompt
gemini -p "$(cat "$PROMPT_FILE")"
