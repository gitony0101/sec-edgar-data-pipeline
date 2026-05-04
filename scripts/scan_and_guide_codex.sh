#!/usr/bin/env bash
set -euo pipefail

# scripts/scan_and_guide_codex.sh
# Scans the project structure and provides context to codex for review planning.

TARGET_DIR="${TARGET_DIR:-sec_edgar_pipeline}"
MODEL="${MODEL:-gemma4:e2b}"
TMP_DIR=".brain/codex_scan"
PROMPT_FILE="$TMP_DIR/project_scan_prompt.txt"
STRUCTURE_FILE="$TMP_DIR/project_structure.txt"
NOTES_FILE="$TMP_DIR/review_notes_list.txt"
FILES_FILE="$TMP_DIR/source_files.txt"

mkdir -p "$TMP_DIR"

if [[ ! -d "$TARGET_DIR" ]]; then
  echo "Error: target directory '$TARGET_DIR' not found."
  echo "Run this script from the project root."
  exit 1
fi

echo "== Current workspace =="
pwd
echo

echo "== Checking required commands =="
command -v codex >/dev/null 2>&1 || { echo "Error: codex not found"; exit 1; }
command -v find >/dev/null 2>&1 || { echo "Error: find not found"; exit 1; }
echo "codex: $(command -v codex)"
if command -v tree >/dev/null 2>&1; then
  echo "tree:  $(command -v tree)"
else
  echo "tree:  not found, will use find fallback"
fi
echo

echo "== Capturing project structure =="
{
  echo "# WORKSPACE"
  pwd
  echo
  echo "# TOP LEVEL"
  ls -la
  echo

  echo "# TARGET TREE"
  if command -v tree >/dev/null 2>&1; then
    tree -a -L 3 "$TARGET_DIR"
  else
    find "$TARGET_DIR" -maxdepth 3 | sort
  fi
  echo

  echo "# TARGET PYTHON FILES"
  find "$TARGET_DIR" -type f | sort
  echo
} > "$STRUCTURE_FILE"

echo "Saved structure to: $STRUCTURE_FILE"

echo "== Capturing source file list =="
find "$TARGET_DIR" -type f | sort > "$FILES_FILE"
echo "Saved file list to: $FILES_FILE"

echo "== Capturing existing review notes =="
if [[ -d "review/FILE_NOTES" ]]; then
  find review/FILE_NOTES -type f | sort > "$NOTES_FILE"
else
  : > "$NOTES_FILE"
fi
echo "Saved note list to: $NOTES_FILE"

echo "== Building codex prompt =="
cat > "$PROMPT_FILE" <<'EOF'
You are reviewing a local Python project in the current workspace.

Your task in this round:
1. Read the project structure provided below
2. Build a concise map of the repository
3. Identify high-priority files for code review
4. Propose the best reading order
5. Do not modify files in this round

Requirements:
- Focus on the current repository only
- Use the provided structure and file list
- If existing review notes are available, use them only as supporting context
- Stay concrete
- Do not give generic software advice
- Do not rewrite code
- Do not apply patches
- Do not expand scope beyond project scanning and review planning

Output format:
1. PROJECT MAP
2. HIGH-PRIORITY FILES
3. PROPOSED READING ORDER
4. WHY THIS ORDER
5. FIRST FILE TO READ DEEPLY NEXT
EOF

{
  echo
  echo "===== PROJECT STRUCTURE ====="
  cat "$STRUCTURE_FILE"
  echo
  echo "===== REVIEW NOTES LIST ====="
  cat "$NOTES_FILE"
  echo
  echo "===== SOURCE FILE LIST ====="
  cat "$FILES_FILE"
} >> "$PROMPT_FILE"

echo "Saved prompt to: $PROMPT_FILE"
echo

echo "== Running codex with local model =="
codex exec \
  --oss \
  -c oss_provider=ollama \
  -m "$MODEL" \
  "$(cat "$PROMPT_FILE")"
