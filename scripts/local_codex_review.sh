#!/usr/bin/env bash
set -euo pipefail

# scripts/local_codex_review.sh
# Unified entrypoint for local model review workflows.
# Source-first review without persona injection.

TARGET_DIR="${TARGET_DIR:-sec_edgar_pipeline}"
MODEL="${MODEL:-gemma4:e2b}"
TMP_DIR=".brain/local_codex_review"
PROMPT_FILE="$TMP_DIR/prompt.txt"
STRUCTURE_FILE="$TMP_DIR/project_structure.txt"
FILES_FILE="$TMP_DIR/source_files.txt"
ARCH_FILE="$TMP_DIR/project_architecture.md"
BOOTSTRAP_FILE=".brain/agent_role_bootstrap.md"
SESSION_FILE=".brain/review_session_memory.md"
RAW_OUTPUT_FILE="$TMP_DIR/raw_output.txt"
REVIEW_OUTPUT_FILE="$TMP_DIR/review_output.txt"

mkdir -p "$TMP_DIR"

usage() {
  echo "Usage: $0 {architecture|review <relative_file_path>}"
  exit 1
}

if [[ $# -lt 1 ]]; then
  usage
fi

MODE="$1"

prepare_context() {
  if command -v tree >/dev/null 2>&1; then
    tree -a -L 3 "$TARGET_DIR" > "$STRUCTURE_FILE"
  else
    find "$TARGET_DIR" -maxdepth 3 | sort > "$STRUCTURE_FILE"
  fi
  find "$TARGET_DIR" -type f | sort > "$FILES_FILE"
}

extract_recent_sessions() {
  if [[ ! -f "$SESSION_FILE" ]]; then
    return
  fi

  python - <<'PY' "$SESSION_FILE"
from pathlib import Path
import sys

text = Path(sys.argv[1]).read_text()
parts = text.split("\n## SESSION ")
if len(parts) <= 1:
    print("")
    raise SystemExit

sessions = ["## SESSION " + p for p in parts[1:]]
print("\n\n".join(sessions[-2:]).strip())
PY
}

validate_review_output() {
  python - <<'PY' "$RAW_OUTPUT_FILE" "$REVIEW_OUTPUT_FILE"
from pathlib import Path
import re
import sys

raw_path = Path(sys.argv[1])
review_path = Path(sys.argv[2])
text = raw_path.read_text(errors="ignore")

fallback_markers = [
    "please provide the file content",
    "please provide the source code",
    "i need the file content",
    "i need the source code",
    "i cannot review the file",
    "i don't have the file content",
]

lower = text.lower()
for marker in fallback_markers:
    if marker in lower:
        print(f"worker-output-invalid: fallback marker detected: {marker}")
        raise SystemExit(2)

pattern = re.compile(
    r"(1\. RESPONSIBILITY SUMMARY\s+.+?2\. LOGIC & PERFORMANCE ANALYSIS\s+.+?3\. SECURITY & STABILITY AUDIT\s+.+?4\. CONSERVATIVE IMPROVEMENT SUGGESTIONS\s+.+)",
    re.DOTALL,
)
matches = list(pattern.finditer(text))
if not matches:
    print("worker-output-invalid: required final sections missing or incomplete")
    raise SystemExit(2)

review_text = matches[-1].group(1).strip()
if review_text.endswith("1. RESPONSIBILITY SUMMARY") or review_text.endswith("4. CONSERVATIVE IMPROVEMENT SUGGESTIONS"):
    print("worker-output-invalid: structured review output ended mid-format")
    raise SystemExit(2)

review_path.write_text(review_text)
print("worker-output-valid")
PY
}

run_local_review_worker() {
  python - <<'PY' "$MODEL" "$PROMPT_FILE" "$RAW_OUTPUT_FILE"
from pathlib import Path
import subprocess
import sys

model = sys.argv[1]
prompt_file = Path(sys.argv[2])
raw_output_file = Path(sys.argv[3])

cmd = [
    "codex",
    "exec",
    "--oss",
    "-c",
    "oss_provider=ollama",
    "-m",
    model,
    prompt_file.read_text(),
]

try:
    result = subprocess.run(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        timeout=75,
        check=False,
    )
    raw_output_file.write_text(result.stdout)
    raise SystemExit(result.returncode)
except subprocess.TimeoutExpired as exc:
    output = exc.stdout or ""
    if isinstance(output, bytes):
        output = output.decode(errors="ignore")
    raw_output_file.write_text(output + "\nworker-output-invalid: timed out before producing a valid final review\n")
    print("worker-output-invalid: timed out before producing a valid final review")
    raise SystemExit(124)
PY
}

# --- MODE: architecture ---
build_architecture_prompt() {
  cat > "$PROMPT_FILE" <<EOF
===== PROJECT DATA =====
$(cat "$STRUCTURE_FILE")

$(cat "$FILES_FILE")

Based ONLY on the data above:
1. Infer the project type and system purpose.
2. Build a concise module map.
3. Identify 3 high-risk areas.

Output format:
1. PROJECT TYPE
2. SYSTEM PURPOSE
3. TOP-LEVEL ARCHITECTURE
4. CORE MODULES
5. RISK AREAS
EOF
}

# --- MODE: review (Source-first + Strict Output) ---
build_review_prompt() {
  local target_file="$1"
  local bootstrap_context=""
  local architecture_context=""
  local session_context=""

  if [[ -f "$BOOTSTRAP_FILE" ]]; then
    bootstrap_context=$(cat "$BOOTSTRAP_FILE")
  fi

  if [[ -f ".brain/project_architecture.md" ]]; then
    architecture_context=$(cat ".brain/project_architecture.md")
  fi

  if [[ -f "$SESSION_FILE" ]]; then
    session_context=$(extract_recent_sessions)
  fi

  cat > "$PROMPT_FILE" <<EOF
### SOURCE CODE TO REVIEW ###
File: $target_file
\`\`\`python
$(cat "$target_file")
\`\`\`

### BOOTSTRAP MEMORY ###
$bootstrap_context

### PROJECT ARCHITECTURE MEMORY ###
$architecture_context

### RECENT SESSION MEMORY ###
$session_context

### TASK ###
Perform the deep review now.

Rules:
- Ground every claim in the visible source code first, then use memory only as supporting context.
- Do not adopt a named persona from memory.
- Do not invent behavior that is not visible in the file or supported by memory.

You must output the final analysis directly.
Do not describe your plan.
Do not describe what you are about to do.
Do not self-correct.
Do not add meta commentary.

Output the final answer immediately in exactly this format:
1. RESPONSIBILITY SUMMARY
2. LOGIC & PERFORMANCE ANALYSIS
3. SECURITY & STABILITY AUDIT
4. CONSERVATIVE IMPROVEMENT SUGGESTIONS
EOF
}

case "$MODE" in
  architecture)
    prepare_context
    build_architecture_prompt
    echo "== Running codex architecture analysis =="
    codex exec --oss -c oss_provider=ollama -m "$MODEL" "$(cat "$PROMPT_FILE")" | tee "$ARCH_FILE"
    ;;
  review)
    if [[ $# -lt 2 ]]; then usage; fi
    TARGET_FILE="$2"
    if [[ ! -f "$TARGET_FILE" ]]; then echo "Error: $TARGET_FILE not found"; exit 1; fi
    prepare_context
    build_review_prompt "$TARGET_FILE"
    echo "== Running codex strict review for $TARGET_FILE =="
    run_local_review_worker || true
    validate_review_output
    cat "$REVIEW_OUTPUT_FILE"
    ;;
  *)
    usage
    ;;
esac
