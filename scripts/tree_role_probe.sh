#!/usr/bin/env bash
set -euo pipefail

# scripts/tree_role_probe.sh
# Build tree-level bootstrap memory without forcing a named persona.

TARGET_DIR="${TARGET_DIR:-sec_edgar_pipeline}"
MODEL="${MODEL:-gemma4:e2b}"
TMP_DIR=".brain/tree_role_probe"
TREE_FILE="$TMP_DIR/tree.txt"
PROMPT_FILE="$TMP_DIR/prompt.txt"
BOOTSTRAP_FILE=".brain/agent_role_bootstrap.md"

mkdir -p "$TMP_DIR"

if [[ ! -d "$TARGET_DIR" ]]; then
  echo "Error: target directory '$TARGET_DIR' not found."
  exit 1
fi

command -v codex >/dev/null 2>&1 || { echo "Error: codex not found"; exit 1; }

echo "== Capturing project tree =="
if command -v tree >/dev/null 2>&1; then
  tree -a -L 3 "$TARGET_DIR" > "$TREE_FILE"
else
  find "$TARGET_DIR" -maxdepth 3 | sort > "$TREE_FILE"
fi

cat > "$PROMPT_FILE" <<EOF
You are inspecting a local software repository from its directory tree only.
At this stage, you cannot see full source code.

Your task:
1. Infer the repository type and likely active areas.
2. State what the tree alone supports and what it does not support.
3. Propose high-leverage files to read next.
4. Produce a concise bootstrap memory for later review rounds.

Rules:
- Do not invent source-level behavior from the tree alone.
- Do not define or force a named professional persona.
- Keep the output factual, compact, and boundary-oriented.
- No file modifications.

Output format:
## PURPOSE
## EVIDENCE LEVEL
## CURRENT REVIEW STANCE
## WHAT THE TREE SUPPORTS
## WHAT THE TREE DOES NOT SUPPORT
## INITIAL HIGH-LEVERAGE TARGETS
## WRITE / READ CONTRACT

===== PROJECT TREE =====
$(cat "$TREE_FILE")
EOF

echo "== Running autonomous role discovery with $MODEL =="
codex exec \
  --oss \
  -c oss_provider=ollama \
  -m "$MODEL" \
  "$(cat "$PROMPT_FILE")" | tee "$BOOTSTRAP_FILE"

echo
echo "Bootstrap memory established: $BOOTSTRAP_FILE"
